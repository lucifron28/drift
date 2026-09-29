import Foundation
import SwiftData
import Combine

@MainActor
final class EditSongViewModel: ObservableObject {
    @Published var title: String
    @Published var artist: String

    init(song: Song) {
        self.title = song.title
        self.artist = song.artist
    }

    @discardableResult
    func saveChanges(to song: Song, context: ModelContext) -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedArtist = artist.trimmingCharacters(in: .whitespacesAndNewlines)

        song.title = trimmedTitle.isEmpty ? "Untitled" : trimmedTitle
        song.artist = trimmedArtist.isEmpty ? "Unknown Artist" : trimmedArtist

        do {
            try context.save()
            return true
        } catch {
            print("Failed to save changes: \(error)")
            return false
        }
    }
}
