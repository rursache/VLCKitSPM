// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "VLCKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .tvOS(.v13),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "VLCKitSPM",
            targets: ["VLCKitSPM", "VLCKitXC"]
        ),
    ],
    targets: [
        .binaryTarget(
           name: "VLCKitXC",
           url: "https://github.com/rursache/VLCKitSPM/releases/download/nightly/VLCKit.xcframework.zip",
           checksum: "f27f696e34a49f66d20ec137aaa01ef8198310390a7b97d67c75757d4bec8ef0"
        ),
        .target(
            name: "VLCKitSPM",
            dependencies: [
                .target(name: "VLCKitXC")
            ], linkerSettings: [
                .linkedFramework("QuartzCore", .when(platforms: [.iOS, .tvOS, .visionOS])),
                .linkedFramework("CoreText", .when(platforms: [.iOS, .tvOS, .watchOS, .visionOS])),
                .linkedFramework("AVFoundation", .when(platforms: [.iOS, .tvOS, .watchOS, .visionOS])),
                .linkedFramework("Security", .when(platforms: [.iOS, .watchOS, .visionOS])),
                .linkedFramework("CFNetwork", .when(platforms: [.iOS, .watchOS, .visionOS])),
                .linkedFramework("AudioToolbox", .when(platforms: [.iOS, .tvOS, .visionOS])),
                .linkedFramework("OpenGLES", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("CoreGraphics", .when(platforms: [.iOS, .watchOS, .visionOS])),
                .linkedFramework("VideoToolbox", .when(platforms: [.iOS, .tvOS, .visionOS])),
                .linkedFramework("CoreMedia", .when(platforms: [.iOS, .tvOS, .watchOS, .visionOS])),
                .linkedLibrary("c++", .when(platforms: [.iOS, .tvOS, .watchOS, .visionOS])),
                .linkedLibrary("xml2", .when(platforms: [.iOS, .tvOS, .watchOS, .visionOS])),
                .linkedLibrary("z", .when(platforms: [.iOS, .tvOS, .watchOS, .visionOS])),
                .linkedLibrary("bz2", .when(platforms: [.iOS, .tvOS, .watchOS, .visionOS])),
                .linkedFramework("Foundation", .when(platforms: [.macOS])),
                .linkedLibrary("iconv")
            ]
        )
    ]
)
