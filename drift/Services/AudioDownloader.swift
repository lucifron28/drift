import Foundation
import SwiftData
import YouTubeKit
import Combine

public enum AudioDownloaderError: LocalizedError {
    case invalidURL
    case invalidYouTubeURL
    case noAudioStreamFound
    case downloadFailed(String)
    case fileSaveFailed(String)
    case downloadAlreadyInProgress

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provided URL is invalid."
        case .invalidYouTubeURL:
            return "Could not extract video information from this YouTube URL."
        case .noAudioStreamFound:
            return "No playable audio stream could be found for this video."
        case .downloadFailed(let reason):
            return "Failed to download audio: \(reason)"
        case .fileSaveFailed(let reason):
            return "Failed to save audio file: \(reason)"
        case .downloadAlreadyInProgress:
            return "A download is already in progress."
        }
    }
}

@MainActor
final class AudioDownloader: ObservableObject {
    @Published var isDownloading: Bool = false
    @Published var progress: Double = 0.0
    @Published var statusMessage: String = ""
    @Published var errorMessage: String? = nil

    init() {}

    func downloadSong(
        from urlString: String,
        customTitle: String? = nil,
        customArtist: String? = nil,
        context: ModelContext
    ) async throws -> Song {
        guard !isDownloading else {
            let error = AudioDownloaderError.downloadAlreadyInProgress
            self.errorMessage = error.localizedDescription
            throw error
        }

        // a. Reset state
        isDownloading = true
        progress = 0.05
        statusMessage = "Validating URL..."
        errorMessage = nil

        do {
            // b. Validate input URL
            let trimmedURLString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let url = URL(string: trimmedURLString),
                  let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https",
                  let host = url.host?.lowercased(),
                  !host.isEmpty else {
                throw AudioDownloaderError.invalidURL
            }

            let isYouTube = host.contains("youtube.com") || host.contains("youtu.be")
            let downloadURL: URL
            let finalTitle: String
            let finalArtist: String
            let fileExtension: String

            // c. If YouTube URL
            if isYouTube {
                statusMessage = "Fetching YouTube metadata..."
                progress = 0.15

                let yt = YouTube(url: url)
                guard !yt.videoID.isEmpty else {
                    throw AudioDownloaderError.invalidYouTubeURL
                }

                let meta = try? await yt.metadata

                // Derive title
                if let customTitle = customTitle?.trimmingCharacters(in: .whitespacesAndNewlines), !customTitle.isEmpty {
                    finalTitle = customTitle
                } else if let metaTitle = meta?.title.trimmingCharacters(in: .whitespacesAndNewlines), !metaTitle.isEmpty {
                    finalTitle = metaTitle
                } else {
                    finalTitle = "YouTube Audio"
                }

                // Derive artist
                if let customArtist = customArtist?.trimmingCharacters(in: .whitespacesAndNewlines), !customArtist.isEmpty {
                    finalArtist = customArtist
                } else {
                    finalArtist = "YouTube"
                }

                statusMessage = "Resolving audio streams..."
                progress = 0.30

                let streams = try await yt.streams
                let audioStreams = streams.filterAudioOnly()

                // Filter audio-only stream (prefer m4a if available for iOS AVFoundation compatibility)
                guard let audioStream = audioStreams.filter({ $0.fileExtension == .m4a }).highestAudioBitrateStream()
                        ?? audioStreams.highestAudioBitrateStream()
                        ?? audioStreams.first else {
                    throw AudioDownloaderError.noAudioStreamFound
                }

                downloadURL = audioStream.url
                let ext = audioStream.fileExtension.rawValue
                fileExtension = ext.isEmpty ? "m4a" : ext
            } else {
                // d. If not a YouTube URL, treat as direct audio stream URL
                downloadURL = url

                if let customTitle = customTitle?.trimmingCharacters(in: .whitespacesAndNewlines), !customTitle.isEmpty {
                    finalTitle = customTitle
                } else {
                    let lastComponent = url.deletingPathExtension().lastPathComponent
                    finalTitle = lastComponent.isEmpty ? "Direct Audio" : lastComponent
                }

                if let customArtist = customArtist?.trimmingCharacters(in: .whitespacesAndNewlines), !customArtist.isEmpty {
                    finalArtist = customArtist
                } else {
                    finalArtist = url.host ?? "Online Audio"
                }

                let ext = url.pathExtension.lowercased()
                fileExtension = ext.isEmpty ? "m4a" : ext
            }

            // e. Download using URLSession
            statusMessage = "Downloading audio..."
            progress = 0.50

            let (tempURL, response) = try await URLSession.shared.download(from: downloadURL)

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                throw AudioDownloaderError.downloadFailed("Server responded with HTTP status code \(httpResponse.statusCode)")
            }

            // f. Determine target local file name and move file
            statusMessage = "Saving audio file..."
            progress = 0.85

            let fileManager = FileManager.default
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                throw AudioDownloaderError.fileSaveFailed("Could not access Documents directory.")
            }

            let filename = "\(UUID().uuidString).\(fileExtension)"
            let destinationURL = documentsDirectory.appendingPathComponent(filename)

            if fileManager.fileExists(atPath: destinationURL.path) {
                try? fileManager.removeItem(at: destinationURL)
            }

            do {
                try fileManager.moveItem(at: tempURL, to: destinationURL)
            } catch {
                throw AudioDownloaderError.fileSaveFailed(error.localizedDescription)
            }

            // g. Insert Song into SwiftData context
            statusMessage = "Adding to library..."
            progress = 0.95

            let song = Song(
                title: finalTitle,
                artist: finalArtist,
                sourceURL: urlString,
                localFileName: filename,
                dateAdded: Date()
            )

            context.insert(song)
            try context.save()

            // h. Finish successfully
            progress = 1.0
            statusMessage = "Downloaded successfully!"
            isDownloading = false
            return song

        } catch {
            // i. Catch and set errorMessage if any step fails
            isDownloading = false
            errorMessage = error.localizedDescription
            statusMessage = "Download failed."
            throw error
        }
    }
}
