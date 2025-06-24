#!/bin/bash

# This script builds an Android project using Qt and CMake.
# Usage: ./android.sh <build_type> <package_type> <abi> <action?>
# Arguments:
#   <build_type>  : The type of build (e.g., Debug, Release)
#   <package_type>: The type of package (apk, aab, both)
#   <abi>         : The ABI to build for (armeabi-v7a, arm64-v8a, x86, x86_64, or 'all')
#   <action?>     : The action to perform after build (install, install_and_run, reinstall_and_run) - optional

# Example:
#   ./android.sh Release apk armeabi-v7a install_and_run


# Package and activity variables
PACKAGE_NAME="hr.envizia.letihomeplus"
MAIN_ACTIVITY=".LetiHomePlus"

BUILD_TYPE="Debug"
SIGN_APK="OFF"
SIGN_AAB="OFF"
BUILD_APK="OFF"
BUILD_AAB="OFF"
BUILD_ALL_ABIS="OFF"
QT_ANDROID_ABIS="x86"  # Default ABI

# Check for 'Release' argument
if [ "$1" == "Release" ]; then
    # Check for required environment variables
    REQUIRED_VARS=("QT_ANDROID_KEYSTORE_ALIAS" "QT_ANDROID_KEYSTORE_PATH" "QT_ANDROID_KEYSTORE_STORE_PASS" "QT_ANDROID_KEYSTORE_KEY_PASS")
    for VAR in "${REQUIRED_VARS[@]}"; do
        if [ -z "${!VAR}" ]; then
            echo "Error: Environment variable $VAR is not set."
            exit 1
        fi
    done

    BUILD_TYPE="Release"
    SIGN_APK="ON"
    SIGN_AAB="ON"
fi

# Check for build type argument (apk, aab, both)
if [ "$2" == "apk" ]; then
    BUILD_APK="ON"
elif [ "$2" == "aab" ]; then
    BUILD_AAB="ON"
elif [ "$2" == "both" ]; then
    BUILD_APK="ON"
    BUILD_AAB="ON"
fi

# Check for 'all' argument or specific ABI
if [ "$3" == "all" ]; then
    BUILD_ALL_ABIS="ON"
    QT_ANDROID_ABIS="armeabi-v7a;arm64-v8a;x86;x86_64"
elif [ -n "$3" ]; then
    QT_ANDROID_ABIS="$3"
fi

# always run from root dir
cd "$( dirname "${BASH_SOURCE[0]}" )"/..

mkdir -p build_android
cd build_android

$HOME/Qt/6.5.3/android_x86/bin/qt-cmake \
    -DANDROID_SDK_ROOT=$HOME/Android/Sdk \
    -DANDROID_NDK_ROOT=$HOME/Android/Sdk/ndk/27.2.12479018 \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DQT_ANDROID_SIGN_APK="$SIGN_APK" \
    -DQT_ANDROID_SIGN_AAB="$SIGN_AAB" \
    -DQT_ANDROID_BUILD_ALL_ABIS="$BUILD_ALL_ABIS" \
    -DQT_ANDROID_ABIS="$QT_ANDROID_ABIS" \
    -GNinja ..

if [ "$BUILD_APK" == "ON" ]; then
    cmake --build . --target apk
fi

if [ "$BUILD_AAB" == "ON" ]; then
    cmake --build . --target aab
fi

# Set APK_FILE and AAB_FILE based on build type
if [ "$BUILD_TYPE" == "Release" ]; then
    APK_FILE="android-build/build/outputs/apk/release/android-build-release-signed.apk"
    AAB_FILE="android-build/build/outputs/bundle/release/android-build-release.aab"
else
    APK_FILE="android-build/build/outputs/apk/debug/android-build-debug.apk"
    AAB_FILE="android-build/build/outputs/bundle/debug/android-build-debug.aab"
fi

# Check for install, install_and_run, or reinstall_and_run argument
if [ "$4" == "install" ]; then
    adb install $APK_FILE
elif [ "$4" == "install_and_run" ]; then
    adb install $APK_FILE
    adb shell am force-stop $PACKAGE_NAME
    adb shell am start -n $PACKAGE_NAME/$MAIN_ACTIVITY
elif [ "$4" == "reinstall_and_run" ]; then
    adb uninstall $PACKAGE_NAME
    adb install $APK_FILE
    adb shell am force-stop $PACKAGE_NAME
    adb shell am start -n $PACKAGE_NAME/$MAIN_ACTIVITY
elif [ "$4" == "build" ]; then
    version_cmakelists="$(\grep -oP 'QT_ANDROID_VERSION_NAME "\K[0-9.]+' ../CMakeLists.txt)"
    cp $APK_FILE LetiHome-$version_cmakelists.apk
    cp $AAB_FILE LetiHome-$version_cmakelists.aab
fi