import Foundation
import AVFoundation
import Combine
import SwiftData

@MainActor
final class AudioPlayerViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var currentSong: Song? = nil
    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0.0
    @Published var duration: Double = 0.0
    @Published var playbackError: String? = nil

    // MARK: - Private Properties
    private var player: AVPlayer? = nil
    private var timeObserverToken: Any? = nil
    private var endObserverToken: (any NSObjectProtocol)? = nil

    // MARK: - Deinit
    deinit {
        if let endObserverToken {
            NotificationCenter.default.removeObserver(endObserverToken)
        }
    }

    // MARK: - Playback Controls
    func play(song: Song) {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
        #endif

        guard FileManager.default.fileExists(atPath: song.localFileURL.path) else {
            playbackError = "Audio file not found."
            return
        }
        playbackError = nil

        stopExistingPlayer()

        let item = AVPlayerItem(url: song.localFileURL)
        let newPlayer = AVPlayer(playerItem: item)
        self.player = newPlayer

        let interval = CMTime(seconds: 0.25, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                self?.handleTimeUpdate(time)
            }
        }

        endObserverToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handlePlaybackEnded()
            }
        }

        newPlayer.play()
        isPlaying = true
        currentSong = song
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func resume() {
        player?.play()
        isPlaying = true
    }

    func stop() {
        player?.pause()
        removeObservers()
        player = nil
        isPlaying = false
        currentSong = nil
        currentTime = 0.0
        duration = 0.0
    }

    func seek(to seconds: Double) {
        let targetTime: Double
        if duration > 0 {
            targetTime = min(max(0.0, seconds), duration)
        } else {
            targetTime = max(0.0, seconds)
        }
        let cmTime = CMTime(seconds: targetTime, preferredTimescale: 600)
        player?.seek(to: cmTime)
        currentTime = targetTime
    }

    func seekRelative(by offset: Double) {
        let targetTime: Double
        if duration > 0 {
            targetTime = min(max(0.0, currentTime + offset), duration)
        } else {
            targetTime = max(0.0, currentTime + offset)
        }
        seek(to: targetTime)
    }

    // MARK: - UI Formatting Helpers
    static func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && !seconds.isNaN && seconds > 0 else {
            return "00:00"
        }
        let totalSeconds = Int(seconds.rounded())
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    // MARK: - Private Helpers
    private func handleTimeUpdate(_ time: CMTime) {
        self.currentTime = time.seconds
        if let currentItem = self.player?.currentItem {
            let durationSeconds = currentItem.duration.seconds
            if durationSeconds.isFinite && !durationSeconds.isNaN && durationSeconds > 0 {
                self.duration = durationSeconds
            }
        }
    }

    private func handlePlaybackEnded() {
        isPlaying = false
        currentTime = 0.0
        player?.seek(to: .zero)
    }

    private func stopExistingPlayer() {
        removeObservers()
        player?.pause()
        player = nil
        currentTime = 0.0
        duration = 0.0
    }

    private func removeObservers() {
        if let timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        if let endObserverToken {
            NotificationCenter.default.removeObserver(endObserverToken)
            self.endObserverToken = nil
        }
    }
}
