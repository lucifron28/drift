import Foundation
import SwiftData

@Model
final class Song {
    @Attribute(.unique) var id: UUID
    var title: String
    var artist: String
    var sourceURL: String
    var localFileName: String
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        sourceURL: String,
        localFileName: String,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.sourceURL = sourceURL
        self.localFileName = localFileName
        self.dateAdded = dateAdded
    }

    var localFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(localFileName)
    }

    var fileExists: Bool {
        FileManager.default.fileExists(atPath: localFileURL.path)
    }

    func deleteLocalFile() {
        guard fileExists else { return }
        do {
            try FileManager.default.removeItem(at: localFileURL)
        } catch {
            print("Failed to delete local file at \(localFileURL.path): \(error)")
        }
    }
}
