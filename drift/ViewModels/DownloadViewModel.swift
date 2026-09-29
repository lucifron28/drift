import Foundation
import SwiftData
import Combine
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class DownloadViewModel: ObservableObject {
    @Published var urlString: String = ""
    @Published var customTitle: String = ""
    @Published var customArtist: String = ""
    @Published var downloader = AudioDownloader()

    private var cancellables = Set<AnyCancellable>()

    init() {
        downloader.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func pasteFromClipboard() {
        #if canImport(UIKit)
        if let string = UIPasteboard.general.string {
            urlString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        #endif
    }

    func clearURL() {
        urlString = ""
    }

    func download(context: ModelContext) async -> Bool {
        do {
            _ = try await downloader.downloadSong(
                from: urlString,
                customTitle: customTitle.isEmpty ? nil : customTitle,
                customArtist: customArtist.isEmpty ? nil : customArtist,
                context: context
            )
            urlString = ""
            customTitle = ""
            customArtist = ""
            return true
        } catch {
            return false
        }
    }
}
