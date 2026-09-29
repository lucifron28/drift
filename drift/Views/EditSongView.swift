import SwiftUI
import SwiftData

struct EditSongView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let song: Song
    @StateObject private var viewModel: EditSongViewModel

    init(song: Song) {
        self.song = song
        _viewModel = StateObject(wrappedValue: EditSongViewModel(song: song))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $viewModel.title)
                    TextField("Artist", text: $viewModel.artist)
                } header: {
                    Text("Song Details")
                } footer: {
                    Text("Edit the display title and artist name for this track.")
                }

                Section("Source Information") {
                    LabeledContent("File", value: song.localFileName)
                        .font(.footnote)
                    LabeledContent("Added", value: song.dateAdded.formatted(date: .abbreviated, time: .shortened))
                        .font(.footnote)
                    if !song.sourceURL.isEmpty {
                        LabeledContent("Source", value: song.sourceURL)
                            .font(.footnote)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            .navigationTitle("Edit Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.saveChanges(to: song, context: modelContext) {
                            dismiss()
                        }
                    }
                    .bold()
                }
            }
        }
    }
}
