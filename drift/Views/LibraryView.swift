import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Song.dateAdded, order: .reverse) private var songs: [Song]

    @StateObject private var libraryVM = LibraryViewModel()
    @EnvironmentObject private var player: AudioPlayerViewModel

    @State private var showingAddSheet: Bool = false
    @State private var songToEdit: Song? = nil
    @State private var showingNowPlaying: Bool = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Group {
                    if songs.isEmpty {
                        emptyStateView
                    } else {
                        songListView
                    }
                }

                if player.currentSong != nil {
                    miniPlayerBar
                }
            }
            .navigationTitle("Drift Library")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                    .accessibilityLabel("Add Song")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddSongView()
            }
            .sheet(item: $songToEdit) { song in
                EditSongView(song: song)
            }
            .sheet(isPresented: $showingNowPlaying) {
                NowPlayingView()
            }
        }
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Songs in Library", systemImage: "music.note.list")
        } description: {
            Text("Download YouTube audio or direct audio streams to build your offline music library.")
        } actions: {
            Button {
                showingAddSheet = true
            } label: {
                Text("Download a Song")
                    .bold()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Song List View
    private var songListView: some View {
        List {
            ForEach(songs) { song in
                let isCurrent = player.currentSong?.id == song.id

                Button {
                    if isCurrent {
                        player.togglePlayPause()
                    } else {
                        player.play(song: song)
                    }
                } label: {
                    HStack(spacing: 12) {
                        // Playback indicator or music note icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isCurrent ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.12))
                                .frame(width: 44, height: 44)

                            if isCurrent && player.isPlaying {
                                Image(systemName: "speaker.wave.3.fill")
                                    .foregroundColor(.green)
                            } else if isCurrent {
                                Image(systemName: "pause.fill")
                                    .foregroundColor(.accentColor)
                            } else {
                                Image(systemName: "music.note")
                                    .foregroundColor(.secondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(song.title)
                                .font(.headline)
                                .foregroundColor(isCurrent ? .accentColor : .primary)
                                .lineLimit(1)

                            HStack(spacing: 6) {
                                Text(song.artist)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)

                                Text("•")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text(song.dateAdded.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        if isCurrent {
                            player.togglePlayPause()
                        } else {
                            player.play(song: song)
                        }
                    } label: {
                        Label(
                            isCurrent && player.isPlaying ? "Pause" : "Play",
                            systemImage: isCurrent && player.isPlaying ? "pause.fill" : "play.fill"
                        )
                    }

                    Button {
                        songToEdit = song
                    } label: {
                        Label("Edit Details", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        libraryVM.deleteSong(song, context: modelContext, player: player)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        libraryVM.deleteSong(song, context: modelContext, player: player)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        songToEdit = song
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.orange)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let song = songs[index]
                    libraryVM.deleteSong(song, context: modelContext, player: player)
                }
            }

            // Extra padding at bottom so mini-player does not obstruct the last item
            if player.currentSong != nil {
                Color.clear
                    .frame(height: 64)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Mini Player Bar
    private var miniPlayerBar: some View {
        Group {
            if let currentSong = player.currentSong {
                VStack(spacing: 0) {
                    // Mini progress indicator
                    GeometryReader { geo in
                        let progress = player.duration > 0 ? player.currentTime / player.duration : 0.0
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: max(0, min(geo.size.width * CGFloat(progress), geo.size.width)), height: 2)
                    }
                    .frame(height: 2)

                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 38, height: 38)

                            Image(systemName: "music.note")
                                .font(.system(size: 18))
                                .foregroundColor(.accentColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentSong.title)
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Text(currentSong.artist)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Button {
                            player.togglePlayPause()
                        } label: {
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title3)
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
                .contentShape(Rectangle())
                .onTapGesture {
                    showingNowPlaying = true
                }
            }
        }
    }
}
