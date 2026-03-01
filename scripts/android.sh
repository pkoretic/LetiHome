#!/bin/bash
set -euo pipefail

# Builds a debug APK of LetiHome+ for a single Android ABI.
# Release builds and AAB packaging are handled by CI (GitHub Actions).
#
# Usage: ./android.sh [options]
#   -a ABI     Target ABI: armeabi-v7a, arm64-v8a, x86, x86_64 (default: x86)
#   -r ACTION  Post-build: install, run, reinstall (default: none)
#   -s         Skip cmake configure if CMakeCache exists
#   -c         Clean build directory first
#   -q PATH    Path to qt-cmake (default: ~/Qt/6.5.3/android_x86/bin/qt-cmake)
#   -d PATH    Android SDK root (default: ~/Android/Sdk)
#   -n PATH    Android NDK root (default: ~/Android/Sdk/ndk/27.2.12479018)
#
# Examples:
#   ./android.sh                              # x86 debug APK (emulator)
#   ./android.sh -a arm64-v8a -r run          # arm64 debug APK, install & launch
#   ./android.sh -a arm64-v8a -r run -s       # same, skip configure
#   ./android.sh -a arm64-v8a -c              # clean build from scratch

PACKAGE_NAME="hr.envizia.letihome"
MAIN_ACTIVITY=".LetiHome"

# Defaults
ABI="x86"
ACTION=""
SKIP_CONFIGURE=false
CLEAN=false
QT_CMAKE="$HOME/Qt/6.5.3/android_x86/bin/qt-cmake"
SDK_ROOT="$HOME/Android/Sdk"
NDK_ROOT="$HOME/Android/Sdk/ndk/27.2.12479018"

# Parse options
while getopts "a:r:scq:d:n:" opt; do
    case $opt in
        a) ABI="$OPTARG" ;;
        r) ACTION="$OPTARG" ;;
        s) SKIP_CONFIGURE=true ;;
        c) CLEAN=true ;;
        q) QT_CMAKE="$OPTARG" ;;
        d) SDK_ROOT="$OPTARG" ;;
        n) NDK_ROOT="$OPTARG" ;;
        *) echo "Unknown option: -$opt" >&2; exit 1 ;;
    esac
done

# Validate ABI
case "$ABI" in
    armeabi-v7a|arm64-v8a|x86|x86_64) ;;
    *) echo "Error: Invalid ABI '$ABI'. Use armeabi-v7a, arm64-v8a, x86, or x86_64." >&2; exit 1 ;;
esac

# Validate action
if [ -n "$ACTION" ]; then
    case "$ACTION" in
        install|run|reinstall) ;;
        *) echo "Error: Invalid action '$ACTION'. Use install, run, or reinstall." >&2; exit 1 ;;
    esac
fi

# Validate tools
if [ ! -f "$QT_CMAKE" ]; then
    echo "Error: qt-cmake not found at: $QT_CMAKE" >&2; exit 1
fi
if [ ! -d "$SDK_ROOT" ]; then
    echo "Error: Android SDK not found at: $SDK_ROOT" >&2; exit 1
fi
if [ ! -d "$NDK_ROOT" ]; then
    echo "Error: Android NDK not found at: $NDK_ROOT" >&2; exit 1
fi
if [ -n "$ACTION" ] && ! command -v adb &>/dev/null; then
    echo "Error: 'adb' is required for -r $ACTION but not found in PATH." >&2; exit 1
fi

# Always run from project root
cd "$(dirname "${BASH_SOURCE[0]}")/.."
PROJECT_ROOT="$(pwd)"
BUILD_DIR="$PROJECT_ROOT/build_android"

# Extract version from CMakeLists.txt
VERSION=$(grep -oP 'QT_ANDROID_VERSION_NAME\s+"\K[0-9.]+' CMakeLists.txt || echo "unknown")

# Clean
if $CLEAN && [ -d "$BUILD_DIR" ]; then
    echo "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"

# Print configuration
echo ""
echo "┌─ LetiHome+ Debug APK (v$VERSION) ─────────────────────────"
echo "│  ABI        : $ABI"
echo "│  Action     : ${ACTION:-(none)}"
echo "│  Qt cmake   : $QT_CMAKE"
echo "│  SDK        : $SDK_ROOT"
echo "│  NDK        : $NDK_ROOT"
echo "└──────────────────────────────────────────────────────"
echo ""

# Configure (qt-cmake)
CMAKE_CACHE="$BUILD_DIR/CMakeCache.txt"

if $SKIP_CONFIGURE && [ -f "$CMAKE_CACHE" ]; then
    echo "Skipping cmake configure (-s, CMakeCache exists)."
else
    echo "Running qt-cmake configure..."
    CMAKE_ARGS=(
        "-DANDROID_SDK_ROOT=$SDK_ROOT"
        "-DANDROID_NDK_ROOT=$NDK_ROOT"
        "-DCMAKE_BUILD_TYPE=Debug"
        "-DQT_ANDROID_BUILD_ALL_ABIS=OFF"
        "-DQT_ANDROID_ABIS=$ABI"
        "-GNinja"
    )
    # If FetchContent source was already downloaded, skip network access
    if [ -d "$BUILD_DIR/_deps/android_openssl-src" ]; then
        CMAKE_ARGS+=("-DFETCHCONTENT_FULLY_DISCONNECTED=ON")
    fi
    CMAKE_ARGS+=("-S" "$PROJECT_ROOT" "-B" "$BUILD_DIR")

    "$QT_CMAKE" "${CMAKE_ARGS[@]}"
fi

# Gradle optimizations
export GRADLE_OPTS="${GRADLE_OPTS:--Dorg.gradle.daemon=true -Dorg.gradle.parallel=true -Dorg.gradle.caching=true -Xmx2g}"

# Remove stale Gradle lock files
find "$BUILD_DIR/android-build/.gradle" -name "*.lock" -delete 2>/dev/null || true

# Build APK
SECONDS=0
echo "Building debug APK ($ABI)..."
cmake --build "$BUILD_DIR" --target apk --parallel

# Verify APK
APK_FILE="$BUILD_DIR/android-build/build/outputs/apk/debug/android-build-debug.apk"
if [ ! -f "$APK_FILE" ]; then
    echo "Error: APK not found at expected path: $APK_FILE" >&2; exit 1
fi

APK_SIZE=$(du -h "$APK_FILE" | cut -f1)
echo "APK ready: $APK_FILE ($APK_SIZE)"

# Post-build actions
case "$ACTION" in
    install)
        echo "Installing APK..."
        adb install "$APK_FILE"
        ;;
    run)
        echo "Installing and launching..."
        adb install "$APK_FILE"
        adb shell am force-stop "$PACKAGE_NAME"
        adb shell am start -n "$PACKAGE_NAME/$MAIN_ACTIVITY"
        ;;
    reinstall)
        echo "Reinstalling and launching..."
        adb uninstall "$PACKAGE_NAME" 2>/dev/null || true
        adb install "$APK_FILE"
        adb shell am force-stop "$PACKAGE_NAME"
        adb shell am start -n "$PACKAGE_NAME/$MAIN_ACTIVITY"
        ;;
esac

# Done
elapsed=$((SECONDS / 60)):$(printf "%02d" $((SECONDS % 60)))
echo ""
echo "Build completed in $elapsed."