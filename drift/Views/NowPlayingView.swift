import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject private var player: AudioPlayerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isScrubbing: Bool = false
    @State private var scrubTime: Double = 0.0

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Album Art / Music Note Header
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.85), Color.blue.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(maxWidth: 280)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 20, x: 0, y: 10)

                    Image(systemName: "music.note")
                        .font(.system(size: 90, weight: .light))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 32)

                // Song Title & Artist
                VStack(spacing: 6) {
                    Text(player.currentSong?.title ?? "No Song Playing")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .foregroundColor(.primary)

                    Text(player.currentSong?.artist ?? "Unknown Artist")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Progress Bar & Time Labels
                VStack(spacing: 8) {
                    let sliderBinding = Binding<Double>(
                        get: {
                            isScrubbing ? scrubTime : player.currentTime
                        },
                        set: { newValue in
                            scrubTime = newValue
                        }
                    )

                    Slider(
                        value: sliderBinding,
                        in: 0...max(player.duration, 1),
                        onEditingChanged: { editing in
                            if editing {
                                isScrubbing = true
                                scrubTime = player.currentTime
                            } else {
                                player.seek(to: scrubTime)
                                isScrubbing = false
                            }
                        }
                    )
                    .tint(.accentColor)

                    HStack {
                        Text(AudioPlayerViewModel.formatTime(isScrubbing ? scrubTime : player.currentTime))
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(AudioPlayerViewModel.formatTime(player.duration))
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)

                // Playback Controls Row
                HStack(spacing: 40) {
                    // Seek Backward 15s
                    Button {
                        player.seekRelative(by: -15)
                    } label: {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 28))
                            .foregroundColor(.primary)
                    }
                    .accessibilityLabel("Seek back 15 seconds")

                    // Play/Pause Large Circle Button
                    Button {
                        player.togglePlayPause()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 72, height: 72)
                                .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)

                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: player.isPlaying ? 0 : 2)
                        }
                    }
                    .accessibilityLabel(player.isPlaying ? "Pause" : "Play")

                    // Seek Forward 15s
                    Button {
                        player.seekRelative(by: 15)
                    } label: {
                        Image(systemName: "goforward.15")
                            .font(.system(size: 28))
                            .foregroundColor(.primary)
                    }
                    .accessibilityLabel("Seek forward 15 seconds")
                }
                .padding(.bottom, 24)

                if let error = player.playbackError {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .accessibilityLabel("Close")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
