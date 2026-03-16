import SwiftUI
import VLCKitSPM

struct PlayerView: View {
    private let url: URL
    private let title: String

    @State private var vm = PlayerViewModel()
    private var isLiveStream: Bool {
        let scheme = url.scheme?.lowercased() ?? ""
        return scheme == "rtsp" || scheme == "rtp" || scheme == "mms" || scheme == "mmsh" || scheme == "udp"
    }

    @State private var showSubtitlePicker = false
    @State private var showAudioPicker = false
    @State private var showVideoPicker = false

    init(video: VideoItem) {
        self.url = video.url
        self.title = video.title
    }

    init(url: URL, title: String) {
        self.url = url
        self.title = title
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    videoArea(geometry: geometry)
                    controlsArea
                }
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.load(url: url) }
        .onDisappear { vm.cleanup() }
        .alert("Subtitles", isPresented: $showSubtitlePicker) {
            Button("Disabled") { vm.selectSubtitleTrack(nil) }
            ForEach(vm.subtitleTracks, id: \.trackId) { track in
                Button(track.trackName) { vm.selectSubtitleTrack(track) }
            }
        }
        .alert("Audio Track", isPresented: $showAudioPicker) {
            ForEach(vm.audioTracks, id: \.trackId) { track in
                Button(track.trackName) { vm.selectAudioTrack(track) }
            }
        }
        .alert("Video Track", isPresented: $showVideoPicker) {
            ForEach(vm.videoTracks, id: \.trackId) { track in
                Button(track.trackName) { vm.selectVideoTrack(track) }
            }
        }
    }

    // MARK: - Video Area

    @ViewBuilder
    private func videoArea(geometry: GeometryProxy) -> some View {
        ZStack {
            Color.black
            VLCPlayerView(player: vm.player)
                .allowsHitTesting(false)

            if vm.isBuffering {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.5)
            }

            if vm.showControls {
                controlsOverlay
                    .transition(.opacity)
            }
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.top, 8)
        .contentShape(Rectangle())
        .onTapGesture { vm.toggleControls() }
        .animation(.easeInOut(duration: 0.3), value: vm.showControls)
        .animation(.easeInOut(duration: 0.3), value: vm.isBuffering)
    }

    private var controlsOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
            HStack(spacing: 48) {
                Button { vm.seekBackward() } label: {
                    Image(systemName: "gobackward.10").font(.title)
                }
                Button { vm.togglePlayPause() } label: {
                    Image(systemName: vm.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                }
                Button { vm.seekForward() } label: {
                    Image(systemName: "goforward.10").font(.title)
                }
            }
            .tint(.white)
        }
    }

    // MARK: - Controls Area

    private var controlsArea: some View {
        VStack(spacing: 20) {
            if !isLiveStream {
                progressSection
            }
            mainControlsRow
            volumeSection
            if !isLiveStream {
                playbackSpeedSection
            }
            mediaInfoSection
        }
        .padding(.horizontal)
    }

    private var progressSection: some View {
        HStack(spacing: 8) {
            Text(vm.currentTime)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 48, alignment: .leading)
            Slider(
                value: Binding(
                    get: { vm.progress },
                    set: { vm.seek(to: $0) }
                ),
                in: 0...1
            )
            .tint(.accentColor)
            Text(vm.duration)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 48, alignment: .trailing)
        }
    }

    private var mainControlsRow: some View {
        HStack(spacing: 0) {
            trackButton(
                icon: "captions.bubble",
                disabled: vm.subtitleTracks.isEmpty,
                action: { showSubtitlePicker = true }
            )
            trackButton(
                icon: "waveform",
                disabled: vm.audioTracks.count <= 1,
                action: { showAudioPicker = true }
            )
            trackButton(
                icon: "film.stack",
                disabled: vm.videoTracks.count <= 1,
                action: { showVideoPicker = true }
            )
            trackButton(
                icon: "stop.fill",
                disabled: false,
                tint: .red,
                action: { vm.stop() }
            )
        }
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func trackButton(icon: String, disabled: Bool, tint: Color? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
        }
        .disabled(disabled)
        .tint(tint)
    }

    // MARK: - Volume

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Volume")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .foregroundStyle(.secondary)
                Slider(
                    value: Binding(
                        get: { Double(vm.volume) },
                        set: { vm.setVolume(Int32($0)) }
                    ),
                    in: 0...200,
                    step: 1
                )
                .tint(.accentColor)
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Playback Speed

    private var playbackSpeedSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Playback Speed")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 0) {
                ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { rate in
                    let isActive = abs(vm.playbackRate - Float(rate)) < 0.01
                    Button { vm.setRate(Float(rate)) } label: {
                        Text(rate == floor(rate) ? String(format: "%.0fx", rate) : String(format: "%.1fx", rate))
                            .font(.subheadline.weight(isActive ? .bold : .regular))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isActive ? AnyShapeStyle(.tint) : AnyShapeStyle(.clear))
                            .foregroundStyle(isActive ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Media Info

    @ViewBuilder
    private var mediaInfoSection: some View {
        if !vm.mediaInfoText.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Media Info")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(vm.mediaInfoText)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

}
