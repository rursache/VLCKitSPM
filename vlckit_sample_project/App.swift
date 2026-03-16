import SwiftUI

@main
struct VLCDemoApp: App {
    @State private var customURL = ""
    @State private var navigateToCustomURL = false

    private var parsedURL: URL? {
        guard !customURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return URL(string: customURL.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                List {
                    Section("Custom URL") {
                        TextField("Enter URL (HTTP, HLS, RTSP, MMS...)", text: $customURL)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        NavigationLink(
                            destination: Group {
                                if let url = parsedURL {
                                    PlayerView(url: url, title: "Custom URL")
                                }
                            }
                        ) {
                            Text("Play")
                        }
                        .disabled(parsedURL == nil)
                    }

                    Section("Sample Videos") {
                        ForEach(VideoItem.samples) { video in
                            NavigationLink(destination: PlayerView(video: video)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(video.title)
                                        .font(.headline)
                                    Text(video.subtitle)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .navigationTitle("VLC Demo")
            }
            .tint(.orange)
        }
    }
}
