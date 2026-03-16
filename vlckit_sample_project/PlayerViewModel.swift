import Foundation
import VLCKitSPM

@Observable
@preconcurrency
final class PlayerViewModel: NSObject, VLCMediaPlayerDelegate {

    let player: VLCMediaPlayer

    var isPlaying = false
    var isBuffering = false
    var currentTime = "--:--"
    var duration = "--:--"
    var progress: Double = 0.0
    var volume: Int32 = 100
    var playbackRate: Float = 1.0
    var showControls = true
    var videoTracks: [VLCMediaPlayer.Track] = []
    var audioTracks: [VLCMediaPlayer.Track] = []
    var subtitleTracks: [VLCMediaPlayer.Track] = []
    var mediaInfoText = ""
    var playerState: VLCMediaPlayerState = .stopped

    private var hideControlsTask: DispatchWorkItem?

    override init() {
        player = VLCMediaPlayer()
        super.init()
        player.delegate = self
        player.audio?.volume = volume
    }

    // MARK: - Public Methods

    func load(url: URL) {
        player.media = VLCMedia(url: url)
        player.play()
        isPlaying = true
        startHideControlsTimer()
    }

    func togglePlayPause() {
        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        restartHideControlsTimer()
    }

    func stop() {
        player.stop()
        resetState()
    }

    func seekForward() {
        player.position = min(player.position + 0.05, 1.0)
        restartHideControlsTimer()
    }

    func seekBackward() {
        player.position = max(player.position - 0.05, 0.0)
        restartHideControlsTimer()
    }

    func seek(to position: Double) {
        player.position = position
        restartHideControlsTimer()
    }

    func setRate(_ rate: Float) {
        player.rate = rate
        playbackRate = rate
        restartHideControlsTimer()
    }

    func setVolume(_ vol: Int32) {
        player.audio?.volume = vol
        volume = vol
        restartHideControlsTimer()
    }

    func selectVideoTrack(_ track: VLCMediaPlayer.Track) {
        track.isSelectedExclusively = true
        restartHideControlsTimer()
    }

    func selectAudioTrack(_ track: VLCMediaPlayer.Track) {
        track.isSelectedExclusively = true
        restartHideControlsTimer()
    }

    func selectSubtitleTrack(_ track: VLCMediaPlayer.Track?) {
        if let track {
            track.isSelectedExclusively = true
        } else {
            for t in player.textTracks where t.isSelected {
                t.isSelected = false
            }
        }
        restartHideControlsTimer()
    }

    func toggleControls() {
        showControls.toggle()
        if showControls {
            startHideControlsTimer()
        } else {
            cancelHideControlsTimer()
        }
    }

    func cleanup() {
        player.stop()
        player.delegate = nil
        cancelHideControlsTimer()
    }

    // MARK: - VLCMediaPlayerDelegate

    nonisolated func mediaPlayerTimeChanged(_ aNotification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.handleTimeChanged()
        }
    }

    nonisolated func mediaPlayerStateChanged(_ newState: VLCMediaPlayerState) {
        DispatchQueue.main.async { [weak self] in
            self?.handleStateChanged()
        }
    }

    // MARK: - Private

    private func handleTimeChanged() {
        progress = player.position
        if isBuffering { isBuffering = false }
        if videoTracks.isEmpty || audioTracks.isEmpty {
            refreshTrackLists()
            refreshMediaInfo()
        }
        currentTime = player.time.stringValue
        let currentMs = player.time.intValue
        let remainingMs = player.remainingTime?.intValue ?? 0
        let totalMs = Int(currentMs) + abs(Int(remainingMs))
        if totalMs > 0 {
            duration = formatTime(milliseconds: totalMs)
        }
    }

    private func handleStateChanged() {
        let state = player.state
        playerState = state
        isPlaying = player.isPlaying
        isBuffering = (state == .buffering)

        if state == .playing {
            refreshTrackLists()
            refreshMediaInfo()
        }

        if state == .stopped || state == .stopping || state == .error {
            resetState()
        }
    }

    private func refreshTrackLists() {
        videoTracks = Array(player.videoTracks)
        audioTracks = Array(player.audioTracks)
        subtitleTracks = Array(player.textTracks)
    }

    private func refreshMediaInfo() {
        guard let _ = player.media else {
            mediaInfoText = ""
            return
        }

        var parts: [String] = []

        for track in player.videoTracks {
            let fourcc = track.fourcc
            let codecName = VLCMedia.codecName(forFourCC: fourcc, trackType: .video)
            let name = codecName.isEmpty ? "Video" : codecName
            if let video = track.video {
                var desc = "\(name) \(video.width)x\(video.height)"
                if track.bitrate > 0 {
                    let mbps = Double(track.bitrate) / 1_000_000.0
                    desc += String(format: " %.1f Mbps", mbps)
                }
                parts.append(desc)
            } else {
                parts.append(name)
            }
        }

        for track in player.audioTracks {
            let fourcc = track.fourcc
            let codecName = VLCMedia.codecName(forFourCC: fourcc, trackType: .audio)
            let name = codecName.isEmpty ? "Audio" : codecName
            if let audio = track.audio {
                let channelDesc: String
                switch audio.channelsNumber {
                case 1: channelDesc = "Mono"
                case 2: channelDesc = "Stereo"
                case 6: channelDesc = "5.1"
                case 8: channelDesc = "7.1"
                default: channelDesc = audio.channelsNumber > 0 ? "\(audio.channelsNumber)ch" : ""
                }
                parts.append(channelDesc.isEmpty ? name : "\(name) \(channelDesc)")
            } else {
                parts.append(name)
            }
        }

        mediaInfoText = parts.joined(separator: " \u{2022} ")
    }

    private func resetState() {
        isPlaying = false
        isBuffering = false
        progress = 0.0
        currentTime = "--:--"
    }

    private func formatTime(milliseconds: Int) -> String {
        let totalSeconds = milliseconds / 1000
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Auto-Hide Controls

    private func startHideControlsTimer() {
        cancelHideControlsTimer()
        let work = DispatchWorkItem { [weak self] in
            self?.showControls = false
        }
        hideControlsTask = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: work)
    }

    private func restartHideControlsTimer() {
        if showControls { startHideControlsTimer() }
    }

    private func cancelHideControlsTimer() {
        hideControlsTask?.cancel()
        hideControlsTask = nil
    }
}
