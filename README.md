# VLCKit SPM — Nightly

Custom-built VLCKit xcframework from the latest VLC libvlc source, targeting all Apple platforms (iOS, tvOS, macOS, visionOS, watchOS + simulators).

This branch tracks nightly/development builds. For stable releases, see the [`master`](https://github.com/rursache/VLCKitSPM/tree/master) branch.

## Installation

Add this repository as a Swift Package dependency pointing to the `nightly` branch:

**In Xcode:** Add Package → set "Dependency Rule" to **Branch** → enter `nightly`.

**In `Package.swift`:**
```swift
.package(url: "https://github.com/rursache/VLCKitSPM", branch: "nightly")
```

## Usage

```swift
import VLCKitSPM
```

See the [VLCKit documentation](https://videolan.videolan.me/VLCKit/) for API details.

## Building

To rebuild the xcframework from source:

```sh
./build_vlckit_latest.sh
```

This clones VLCKit + VLC from VideoLAN, applies platform patches (including macOS fixes), builds all platform slices, and produces a unified `VLCKit.xcframework`.

## Thanks

Based on [tylerjonesio](https://github.com/tylerjonesio/vlckit-spm)'s idea.
