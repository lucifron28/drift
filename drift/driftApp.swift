import SwiftUI
import SwiftData

@main
struct driftApp: App {
    let container: ModelContainer
    @StateObject private var player = AudioPlayerViewModel()

    init() {
        do {
            container = try ModelContainer(for: Song.self)
        } catch {
            fatalError("Failed to initialize ModelContainer for Song: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(player)
        }
        .modelContainer(container)
    }
}
