# Nightly Release Update

Steps to refresh the `nightly-build` GitHub release and the `nightly` branch after a fresh local build of `VLCKit.xcframework`

## Prerequisites

- Fresh `VLCKit.xcframework/` directory at the repo root (produced by `build_vlckit_latest.sh` or equivalent)
- `gh` CLI authenticated with push/release permissions on `rursache/VLCKitSPM`
- Working tree clean apart from the new `VLCKit.xcframework/`

## Steps

1. Make sure you are on the `nightly` branch and up to date

   ```bash
   git checkout nightly
   git pull --ff-only
   ```

2. Zip the framework at the repo root (output filename must be `VLCKit.xcframework.zip`)

   ```bash
   zip -ry VLCKit.xcframework.zip VLCKit.xcframework
   ```

3. Compute the SHA-256 checksum

   ```bash
   shasum -a 256 VLCKit.xcframework.zip | awk '{print $1}'
   ```

4. Update the `checksum:` value of the `VLCKitXC` `binaryTarget` in `Package.swift` with the new SHA-256

5. Upload the zip to the existing `nightly-build` release, replacing the previous asset

   ```bash
   gh release upload nightly-build VLCKit.xcframework.zip --clobber
   ```

6. Verify the asset on GitHub matches the local zip (size and digest)

   ```bash
   gh release view nightly-build --json assets --jq '.assets[] | {name, size, digest, updatedAt}'
   stat -f "%z" VLCKit.xcframework.zip
   ```

7. Commit the `Package.swift` checksum bump and push

   ```bash
   git add Package.swift
   git commit -m "Update nightly xcframework checksum (YYYY-MM-DD)

   Platforms: iOS, tvOS, macOS, visionOS, watchOS (9 slices)"
   git push origin nightly
   ```

## Notes

- The release `publishedAt` date does not change when an asset is replaced in-place, only `updatedAt` on the asset itself
- The `nightly-build` tag and release are reused indefinitely, never recreate them
- `VLCKit.xcframework/` and `VLCKit.xcframework.zip` are not tracked in git, leave them untracked or delete after upload
- The monthly `update-vlckit.yml` workflow handles versioned (`vX.Y.Z`) releases on `master`, it does not touch nightly
