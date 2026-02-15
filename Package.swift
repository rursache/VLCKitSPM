// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "VLCKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "VLCKitSPM",
            targets: ["VLCKitSPM"]
        ),
    ],
    targets: [
        .binaryTarget(
           name: "VLCKitXC",
           url: "https://github.com/rursache/VLCKitSPM/releases/download/v4.0.0a9/VLCKit.xcframework.zip",
           checksum: "e3e19f05a4b0ec1c19fee50f50deca893f858aa5157549a0fbcf6ee985cfc4d2"
        ),
        .target(
            name: "VLCKitSPM",
            dependencies: [
                .target(name: "VLCKitXC")
            ], linkerSettings: [
                .linkedFramework("QuartzCore", .when(platforms: [.iOS])),
                .linkedFramework("CoreText", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("AVFoundation", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("Security", .when(platforms: [.iOS])),
                .linkedFramework("CFNetwork", .when(platforms: [.iOS])),
                .linkedFramework("AudioToolbox", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("OpenGLES", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("CoreGraphics", .when(platforms: [.iOS])),
                .linkedFramework("VideoToolbox", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("CoreMedia", .when(platforms: [.iOS, .tvOS])),
                .linkedLibrary("c++", .when(platforms: [.iOS, .tvOS])),
                .linkedLibrary("xml2", .when(platforms: [.iOS, .tvOS])),
                .linkedLibrary("z", .when(platforms: [.iOS, .tvOS])),
                .linkedLibrary("bz2", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("Foundation", .when(platforms: [.macOS])),
                .linkedLibrary("iconv")
            ]
        )
    ]
)
