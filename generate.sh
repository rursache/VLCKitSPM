#!/bin/sh
set -e

# Auto-detect latest VLCKit from VideoLAN unstable builds
echo "Finding latest VLCKit..."
LATEST_FILE=$(curl -sL https://download.videolan.org/pub/cocoapods/unstable/ | \
    grep -oE 'href="(VLCKit-[0-9][^"]+\.tar\.xz)"' | \
    grep -oE 'VLCKit-[0-9][^"]+\.tar\.xz' | \
    sort -V | tail -1)

if [ -z "$LATEST_FILE" ]; then
    echo "Error: Could not find any VLCKit tar.xz files"
    exit 1
fi

XC_FRAMEWORK_URL="https://download.videolan.org/pub/cocoapods/unstable/$LATEST_FILE"
XC_FRAMEWORK_LOCATION=".tmp/VLCKit-binary/VLCKit.xcframework"

# Extract version
VERSION=$(echo "$XC_FRAMEWORK_URL" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+[a-z][0-9]\+')
echo "Latest version: $VERSION"
echo "URL: $XC_FRAMEWORK_URL"

# Download and package steps...
mkdir -p .tmp/
echo "Downloading..."
wget -O .tmp/VLCKit.tar.xz "$XC_FRAMEWORK_URL"
echo "Extracting..."
tar -xf .tmp/VLCKit.tar.xz -C .tmp/
ditto -c -k --sequesterRsrc --keepParent "$XC_FRAMEWORK_LOCATION" "./VLCKit.xcframework.zip"

# Get checksum
CHECKSUM=$(swift package compute-checksum "./VLCKit.xcframework.zip")
echo "Checksum: $CHECKSUM"

# Update Package.swift
sed -i '' \
    -e "s|/download/v[^/]*/|/download/v$VERSION/|" \
    -e "s|checksum: \"[a-f0-9]\{64\}\"|checksum: \"$CHECKSUM\"|" \
    "./Package.swift"

# Copy license and cleanup...
cp -f .tmp/VLCKit-binary/COPYING.txt ./LICENSE
rm -rf .tmp/

# Announce finish
echo "\nDone\n"
echo "Push to git and create a new release with version tag: 'v$VERSION'"
echo "then include the 'VLCKit.xcframework.zip' in that release"
