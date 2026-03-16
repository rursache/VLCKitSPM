# VLCKit SPM

A Swift Package Manager wrapper for [VLCKit](https://code.videolan.org/videolan/VLCKit), distributing pre-built binaries for iOS, macOS, tvOS and visionOS as a single Swift Package.

Binaries are sourced from [VideoLAN's unstable builds](https://download.videolan.org/pub/cocoapods/unstable/) and repackaged as an xcframework attached to GitHub releases.

## Installation

Add this repository as a Swift Package dependency in Xcode:
```
https://github.com/rursache/VLCKitSPM
```

> **Note:** VLCKit upstream versions contain letters (e.g. `4.0.0a18`), which are not valid semantic versions. Xcode and SPM cannot resolve these through range-based version requirements. You **must** use **Exact Version** when adding the dependency:
>
> In Xcode: Add Package → set "Dependency Rule" to **Exact Version** → enter the version (e.g. `4.0.0a18`).
>
> In `Package.swift`:
> ```swift
> .package(url: "https://github.com/rursache/VLCKitSPM", exact: "4.0.0a18")
> ```

## Usage

```swift
import VLCKitSPM
```

See the [VLCKit documentation](https://videolan.videolan.me/VLCKit/) for API details.

For a sample project, see [vlckit_sample_project](vlckit_sample_project/).

## Automated Updates

A GitHub Actions workflow runs on the 1st of every month to check for new VLCKit releases. When a new version is found it:

1. Downloads the latest `VLCKit-*.tar.xz` from VideoLAN
2. Packages the xcframework into a zip
3. Updates `Package.swift` with the new release URL and checksum
4. Creates a tagged GitHub release with the zip attached

## Local Building

To manually generate and update the package with the latest VLCKit binaries:

```sh
./generate.sh
```

This will auto-detect the latest version, download it, update `Package.swift`, and produce `VLCKit.xcframework.zip` for upload to a GitHub release.

## Thanks

Based on [tylerjonesio](https://github.com/tylerjonesio/vlckit-spm)'s idea.
