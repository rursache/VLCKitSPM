#!/bin/bash
# build_vlckit_latest.sh
# Standalone script to build a unified VLCKit.xcframework for all Apple platforms.
# Clones VLCKit + VLC from scratch, applies patches, builds all platforms,
# and merges into one unified xcframework.
#
# Usage: ./build_vlckit_latest.sh [output_directory]

set -e

#######################################
# Configuration
#######################################
VLCKIT_REPO="https://code.videolan.org/videolan/VLCKit.git"
VLC_REPO="https://code.videolan.org/videolan/vlc.git"
OUTPUT_DIR="${1:-.}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/vlckit_build_${TIMESTAMP}.XXXXXX")
LOG_DIR="${WORK_DIR}/logs"

PLATFORMS=("iOS" "tvOS" "macOS" "xrOS" "watchOS")

# Returns build flags for a given platform
# Flags for compileAndBuildVLCKit.sh: platform flag, -r (release), -f (framework), -n (no network)
platform_flags() {
    case "$1" in
        iOS)     echo "-rf -n" ;;
        tvOS)    echo "-trf -n" ;;
        macOS)   echo "-xrf -n" ;;
        xrOS)    echo "-irf -n" ;;
        watchOS) echo "-wrf -n" ;;
        *)       echo ""; return 1 ;;
    esac
}

#######################################
# Helpers
#######################################
info() {
    local green="\033[1;32m"
    local normal="\033[0m"
    echo -e "[${green}$(date '+%H:%M:%S')${normal}] $1"
}

error() {
    local red="\033[1;31m"
    local normal="\033[0m"
    echo -e "[${red}$(date '+%H:%M:%S') ERROR${normal}] $1" >&2
}

elapsed() {
    local start=$1
    local end=$(date +%s)
    local diff=$((end - start))
    local mins=$((diff / 60))
    local secs=$((diff % 60))
    echo "${mins}m ${secs}s"
}

cleanup() {
    if [ "${KEEP_WORK_DIR:-no}" = "yes" ]; then
        info "Keeping working directory: ${WORK_DIR}"
    else
        info "Cleaning up working directory: ${WORK_DIR}"
        rm -rf "${WORK_DIR}"
    fi
}

#######################################
# Prerequisites check
#######################################
check_prerequisites() {
    info "Checking prerequisites..."

    local missing=0

    if ! command -v git &>/dev/null; then
        error "git is not installed"
        missing=1
    fi

    if ! command -v python3 &>/dev/null; then
        error "python3 is not installed"
        missing=1
    fi

    if ! command -v xcodebuild &>/dev/null; then
        error "Xcode command line tools are not installed"
        missing=1
    fi

    if ! xcode-select -p &>/dev/null; then
        error "Xcode is not selected (run xcode-select --install)"
        missing=1
    fi

    if [ $missing -ne 0 ]; then
        error "Missing prerequisites. Aborting."
        exit 1
    fi

    info "Prerequisites OK (git, python3, Xcode)"
}

#######################################
# Main
#######################################
SCRIPT_START=$(date +%s)

trap cleanup EXIT

# Resolve output directory to absolute path
if [ -d "${OUTPUT_DIR}" ]; then
    OUTPUT_DIR=$(cd "${OUTPUT_DIR}" && pwd)
else
    mkdir -p "${OUTPUT_DIR}"
    OUTPUT_DIR=$(cd "${OUTPUT_DIR}" && pwd)
fi

info "============================================"
info "VLCKit Unified XCFramework Builder"
info "============================================"
info "Output directory: ${OUTPUT_DIR}"
info "Working directory: ${WORK_DIR}"
info ""

check_prerequisites

mkdir -p "${LOG_DIR}"

#######################################
# Step 1: Clone VLCKit
#######################################
info "Step 1: Cloning VLCKit repository..."
step_start=$(date +%s)
git clone "${VLCKIT_REPO}" --branch master --single-branch "${WORK_DIR}/VLCKit" 2>&1 | tail -5
info "VLCKit cloned in $(elapsed $step_start)"

#######################################
# Step 2: Clone VLC into libvlc/vlc
#######################################
info "Step 2: Cloning VLC (libvlc) repository..."
step_start=$(date +%s)
mkdir -p "${WORK_DIR}/VLCKit/libvlc"
git clone "${VLC_REPO}" --branch master --single-branch "${WORK_DIR}/VLCKit/libvlc/vlc" 2>&1 | tail -5
info "VLC cloned in $(elapsed $step_start)"

#######################################
# Step 3: Get HEAD hash and patch compileAndBuildVLCKit.sh
#######################################
info "Step 3: Patching TESTEDHASH to match VLC HEAD..."
VLC_HEAD_HASH=$(git -C "${WORK_DIR}/VLCKit/libvlc/vlc" rev-parse HEAD)
info "VLC HEAD commit: ${VLC_HEAD_HASH}"

# Replace the TESTEDHASH line with the actual HEAD hash
sed -i '' "s/^TESTEDHASH=\"[a-f0-9]*\"/TESTEDHASH=\"${VLC_HEAD_HASH}\"/" "${WORK_DIR}/VLCKit/compileAndBuildVLCKit.sh"
info "TESTEDHASH updated in compileAndBuildVLCKit.sh"

#######################################
# Step 4: Apply patches
#######################################
info "Step 4: Applying patches to VLC..."
step_start=$(date +%s)
PATCH_DIR="${WORK_DIR}/VLCKit/libvlc/patches"
if [ -d "${PATCH_DIR}" ] && ls "${PATCH_DIR}"/*.patch &>/dev/null; then
    cd "${WORK_DIR}/VLCKit/libvlc/vlc"
    git am "${PATCH_DIR}"/*.patch 2>&1 | tee "${LOG_DIR}/patches.log" | tail -20
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        error "Patch application failed. See ${LOG_DIR}/patches.log"
        git am --abort 2>/dev/null || true
        exit 1
    fi
    PATCH_COUNT=$(ls -1 "${PATCH_DIR}"/*.patch | wc -l | tr -d ' ')
    info "${PATCH_COUNT} patches applied successfully in $(elapsed $step_start)"
else
    info "No patches found to apply"
fi

#######################################
# Step 4b: Apply build fixes
#######################################
info "Step 4b: Applying build fixes..."

VLCKIT_DIR="${WORK_DIR}/VLCKit"
VLC_DIR="${VLCKIT_DIR}/libvlc/vlc"

# Fix 1: Platform-specific deployment targets in compileAndBuildVLCKit.sh
# The original script uses IPHONEOS_DEPLOYMENT_TARGET for all platforms,
# which breaks macOS/tvOS/watchOS builds on newer Xcode.
sed -i '' '/local deploymentTargetFlag=""/,/fi/{
s/if \[ "\$XROS" != "yes" \]; then/if [ "$MACOS" = "yes" ]; then\
        deploymentTargetFlag="MACOSX_DEPLOYMENT_TARGET=\${SDK_MIN}"\
    elif [ "$TVOS" = "yes" ]; then\
        deploymentTargetFlag="TVOS_DEPLOYMENT_TARGET=\${SDK_MIN}"\
    elif [ "$WATCHOS" = "yes" ]; then\
        deploymentTargetFlag="WATCHOS_DEPLOYMENT_TARGET=\${SDK_MIN}"\
    elif [ "$XROS" != "yes" ]; then/
}' "${VLCKIT_DIR}/compileAndBuildVLCKit.sh"

# Fix 2: Change SDKROOT from xros to auto for multi-platform support
sed -i '' 's/SDKROOT = xros;/SDKROOT = auto;/g' "${VLCKIT_DIR}/VLCKit.xcodeproj/project.pbxproj"

# Fix 3: Add -ld64 linker flag for macOS (fixes duplicate symbol errors with new linker)
# Use perl instead of sed to avoid BSD sed tab-handling issues that corrupt the pbxproj
perl -i -pe 'if (!$done && /\"OTHER_LDFLAGS\[sdk=xros\*\]\"/) {
    print "\t\t\t\t\"OTHER_LDFLAGS[sdk=macosx*]\" = (\n\t\t\t\t\t\"-ObjC\",\n\t\t\t\t\t\"-ld64\",\n\t\t\t\t);\n";
    $done = 1;
}' "${VLCKIT_DIR}/VLCKit.xcodeproj/project.pbxproj"

# Fix 4: Force-disable dup3/pipe2 on Apple platforms
# Meson may incorrectly detect these during cross-compilation (e.g. simulator builds
# picking up the native macOS config), but dup3/pipe2 are not available in Apple SDKs.
# Replace the #ifdef checks to also exclude __APPLE__, ensuring the safe fallbacks
# (dup2 + vlc_cloexec, pipe + vlc_cloexec) are always used on Apple.
sed -i '' 's/#ifdef HAVE_DUP3/#if defined(HAVE_DUP3) \&\& !defined(__APPLE__)/' "${VLC_DIR}/src/posix/filesystem.c"
sed -i '' 's/#ifdef HAVE_PIPE2/#if defined(HAVE_PIPE2) \&\& !defined(__APPLE__)/' "${VLC_DIR}/src/posix/filesystem.c"

# Fix 5: Make json callback functions weak to prevent duplicate symbol errors
# when chromecast and webservices plugins are statically linked together
sed -i '' 's/^void json_parse_error(void \*data, const char \*msg)$/__attribute__((weak)) void json_parse_error(void *data, const char *msg)/' \
    "${VLC_DIR}/modules/misc/webservices/json_helper.h"
sed -i '' 's/^size_t json_read(void \*data, void \*buf, size_t size)$/__attribute__((weak)) size_t json_read(void *data, void *buf, size_t size)/' \
    "${VLC_DIR}/modules/misc/webservices/json_helper.h"
sed -i '' 's/^void json_parse_error(void \*data, const char \*msg)$/__attribute__((weak)) void json_parse_error(void *data, const char *msg)/' \
    "${VLC_DIR}/modules/stream_out/chromecast/chromecast_ctrl.cpp"
sed -i '' 's/^size_t json_read(void \*data, void \*buf, size_t size)$/__attribute__((weak)) size_t json_read(void *data, void *buf, size_t size)/' \
    "${VLC_DIR}/modules/stream_out/chromecast/chromecast_ctrl.cpp"

info "Build fixes applied"

#######################################
# Step 5: Build all platforms
#######################################
info "Step 5: Building all platforms..."
info ""

BUILD_RESULTS=()

for platform in "${PLATFORMS[@]}"; do
    info "--------------------------------------------"
    info "Building ${platform}..."
    info "--------------------------------------------"
    platform_start=$(date +%s)
    platform_log="${LOG_DIR}/build_${platform}.log"

    cd "${WORK_DIR}/VLCKit"

    flags=$(platform_flags "$platform")

    info "Running: ./compileAndBuildVLCKit.sh ${flags}"
    info "Log: ${platform_log}"

    set +e
    # Use bash explicitly and split flags properly
    bash -c "./compileAndBuildVLCKit.sh ${flags}" > "${platform_log}" 2>&1
    build_status=$?
    set -e

    platform_elapsed=$(elapsed $platform_start)

    if [ $build_status -eq 0 ]; then
        info "${platform} build SUCCEEDED in ${platform_elapsed}"
        BUILD_RESULTS+=("${platform}: SUCCESS (${platform_elapsed})")
    else
        error "${platform} build FAILED (exit code ${build_status}) after ${platform_elapsed}"
        error "Check log: ${platform_log}"
        # Show last 30 lines of log for debugging
        echo "--- Last 30 lines of ${platform} build log ---"
        tail -30 "${platform_log}" || true
        echo "--- End of log excerpt ---"
        BUILD_RESULTS+=("${platform}: FAILED (${platform_elapsed})")
        exit 1
    fi
    info ""
done

#######################################
# Step 6: Merge into unified xcframework
#######################################
info "Step 6: Merging per-platform xcframeworks into unified VLCKit.xcframework..."
step_start=$(date +%s)

cd "${WORK_DIR}/VLCKit"

XC_ARGS=""
SLICES_FOUND=0

for platform in "${PLATFORMS[@]}"; do
    xcfw_dir="build/${platform}/VLCKit.xcframework"
    if [ ! -d "${xcfw_dir}" ]; then
        info "Skipping ${platform} -- xcframework not found at ${xcfw_dir}"
        continue
    fi

    info "Processing ${platform} xcframework..."

    # Iterate over slice directories inside the xcframework
    for slice_dir in "${xcfw_dir}"/*/; do
        # Skip Info.plist and non-directories
        [ -d "${slice_dir}" ] || continue
        slice_name=$(basename "${slice_dir}")
        [ "${slice_name}" = "." ] || [ "${slice_name}" = ".." ] && continue

        framework_path="${slice_dir}VLCKit.framework"
        if [ -d "${framework_path}" ]; then
            abs_framework_path=$(cd "${framework_path}" && pwd)
            XC_ARGS="${XC_ARGS} -framework ${abs_framework_path}"
            SLICES_FOUND=$((SLICES_FOUND + 1))
            info "  Found slice: ${slice_name}"

            # Check for dSYM in the slice directory
            dsym_path="${slice_dir}dSYMs/VLCKit.framework.dSYM"
            if [ -d "${dsym_path}" ]; then
                abs_dsym_path=$(cd "${dsym_path}" && pwd)
                XC_ARGS="${XC_ARGS} -debug-symbols ${abs_dsym_path}"
                info "    + dSYM found"
            fi
        fi
    done
done

if [ $SLICES_FOUND -eq 0 ]; then
    error "No framework slices found. Cannot create unified xcframework."
    error "Check the build logs in ${LOG_DIR}/"
    exit 1
fi

info "Creating unified VLCKit.xcframework with ${SLICES_FOUND} slices..."

UNIFIED_OUTPUT="${WORK_DIR}/VLCKit/build/unified/VLCKit.xcframework"
rm -rf "${UNIFIED_OUTPUT}"
mkdir -p "$(dirname "${UNIFIED_OUTPUT}")"

# shellcheck disable=SC2086
xcodebuild -create-xcframework ${XC_ARGS} -output "${UNIFIED_OUTPUT}" 2>&1 | tee "${LOG_DIR}/merge_xcframework.log"

if [ ! -d "${UNIFIED_OUTPUT}" ]; then
    error "Failed to create unified VLCKit.xcframework"
    exit 1
fi

info "Unified xcframework created in $(elapsed $step_start)"

#######################################
# Step 7: Copy to output directory
#######################################
info "Step 7: Copying unified VLCKit.xcframework to output directory..."

FINAL_OUTPUT="${OUTPUT_DIR}/VLCKit.xcframework"
rm -rf "${FINAL_OUTPUT}"
cp -R "${UNIFIED_OUTPUT}" "${FINAL_OUTPUT}"

info "Copied to: ${FINAL_OUTPUT}"

#######################################
# Step 8: Cleanup
#######################################
info "Step 8: Cleaning up working directory..."
cleanup

#######################################
# Summary
#######################################
TOTAL_ELAPSED=$(elapsed $SCRIPT_START)

echo ""
info "============================================"
info "BUILD SUMMARY"
info "============================================"
info "Total build time: ${TOTAL_ELAPSED}"
info "VLC commit: ${VLC_HEAD_HASH}"
info ""
info "Per-platform results:"
for result in "${BUILD_RESULTS[@]}"; do
    info "  ${result}"
done
info ""
info "Unified xcframework slices: ${SLICES_FOUND}"
info "Output: ${FINAL_OUTPUT}"
info ""

# Show contents of the final xcframework
if [ -d "${FINAL_OUTPUT}" ]; then
    info "XCFramework contents:"
    for d in "${FINAL_OUTPUT}"/*/; do
        [ -d "$d" ] || continue
        dname=$(basename "$d")
        [ "$dname" = "." ] || [ "$dname" = ".." ] && continue
        info "  ${dname}"
    done
fi

info ""
info "============================================"
info "Done!"
info "============================================"
