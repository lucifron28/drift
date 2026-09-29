import SwiftUI
import SwiftData

struct AddSongView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = DownloadViewModel()
    @State private var showSuccessAlert = false

    private struct PresetSample: Identifiable {
        let id = UUID()
        let name: String
        let url: String
        let title: String
        let artist: String
    }

    private let sampleLinks: [PresetSample] = [
        PresetSample(
            name: "Direct MP3 Stream (SoundHelix 1)",
            url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
            title: "SoundHelix Song 1",
            artist: "SoundHelix"
        ),
        PresetSample(
            name: "Direct MP3 Stream (SoundHelix 2)",
            url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
            title: "SoundHelix Song 2",
            artist: "SoundHelix"
        ),
        PresetSample(
            name: "YouTube Sample (Rick Astley)",
            url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            title: "Never Gonna Give You Up",
            artist: "Rick Astley"
        )
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 8) {
                        TextField("Enter YouTube or audio URL", text: $viewModel.urlString)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)

                        if !viewModel.urlString.isEmpty {
                            Button {
                                viewModel.clearURL()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            viewModel.pasteFromClipboard()
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Source URL")
                } footer: {
                    Text("Paste a YouTube video link or direct MP3/M4A audio link.")
                }

                Section("Optional Metadata") {
                    TextField("Custom Title (Optional)", text: $viewModel.customTitle)
                    TextField("Custom Artist (Optional)", text: $viewModel.customArtist)
                }

                Section("Preset Samples") {
                    ForEach(sampleLinks) { sample in
                        Button {
                            viewModel.urlString = sample.url
                            viewModel.customTitle = sample.title
                            viewModel.customArtist = sample.artist
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sample.name)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text(sample.url)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        Task {
                            let success = await viewModel.download(context: modelContext)
                            if success {
                                showSuccessAlert = true
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.downloader.isDownloading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding(.trailing, 8)
                                Text("Downloading...")
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("Download to Library")
                            }
                            Spacer()
                        }
                        .bold()
                    }
                    .disabled(viewModel.urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.downloader.isDownloading)

                    if viewModel.downloader.isDownloading || !viewModel.downloader.statusMessage.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ProgressView(value: viewModel.downloader.progress)
                                .tint(.accentColor)
                            HStack {
                                Text(viewModel.downloader.statusMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(viewModel.downloader.progress * 100))%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if let error = viewModel.downloader.errorMessage {
                    Section {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.footnote)
                                .foregroundColor(.red)
                        }
                    } header: {
                        Text("Error")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Download Complete", isPresented: $showSuccessAlert) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("The song was downloaded and added to your library.")
            }
        }
    }
}
