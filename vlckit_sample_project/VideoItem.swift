import Foundation

struct VideoItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let url: URL

    static let samples: [VideoItem] = [
        VideoItem(
            title: "Big Buck Bunny",
            subtitle: "MP4 - 720p (Blender Foundation)",
            url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!
        ),
        VideoItem(
            title: "Elephant's Dream",
            subtitle: "MP4 - 720p (Blender Foundation)",
            url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")!
        ),
        VideoItem(
            title: "Sintel",
            subtitle: "MP4 - 720p (Blender Foundation)",
            url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4")!
        ),
        VideoItem(
            title: "Tears of Steel",
            subtitle: "MP4 - 720p (Blender Foundation)",
            url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4")!
        ),
        VideoItem(
            title: "Apple HLS - Bipbop",
            subtitle: "HLS - Adaptive Bitrate (Apple)",
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
        ),
        VideoItem(
            title: "Sintel HLS",
            subtitle: "HLS - Adaptive Bitrate (Bitmovin)",
            url: URL(string: "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8")!
        ),
        VideoItem(
            title: "Multi-Subtitle Test",
            subtitle: "MKV - 16 SSA Subtitle Tracks (FFmpeg Samples)",
            url: URL(string: "https://samples.ffmpeg.org/Matroska/subtitles/SSA_15subtitles.mkv")!
        ),
        VideoItem(
            title: "Multi-Audio Test",
            subtitle: "MKV - 2 Audio + 7 Subtitle Tracks (Matroska Suite)",
            url: URL(string: "https://github.com/ietf-wg-cellar/matroska-test-files/raw/master/test_files/test5.mkv")!
        ),
        VideoItem(
            title: "Multi-Track Test",
            subtitle: "MKV - 2 Video, 2 Audio, 2 Subtitle Tracks",
            url: URL(string: "https://samples.mplayerhq.hu/Matroska/multiple_tracks.mkv")!
        ),
    ]
}
