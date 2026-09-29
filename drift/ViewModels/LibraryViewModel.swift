import Foundation
import SwiftData
import Combine

@MainActor
final class LibraryViewModel: ObservableObject {
    init() {}

    func deleteSong(_ song: Song, context: ModelContext, player: AudioPlayerViewModel) {
        if player.currentSong?.id == song.id {
            player.stop()
        }
        song.deleteLocalFile()
        context.delete(song)
        try? context.save()
    }
}
