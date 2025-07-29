param(
    [Parameter(Mandatory=$false)]
    [string]$build_type = "Debug",

    [Parameter(Mandatory=$false)]
    [ValidateSet("apk", "aab", "both")]
    [string]$package_type,

    [Parameter(Mandatory=$false)]
    [string]$abi = "x86",

    [Parameter(Mandatory=$false)]
    [ValidateSet("install", "install_and_run", "reinstall_and_run", "build")]
    [string]$action
)

<#
.SYNOPSIS
This script builds an Android project using Qt and CMake.

.DESCRIPTION
Usage: .\android.ps1 <build_type> <package_type> <abi> <action?>

Arguments:
  <build_type>  : The type of build (e.g., Debug, Release)
  <package_type>: The type of package (apk, aab, both)
  <abi>         : The ABI to build for (armeabi-v7a, arm64-v8a, x86, x86_64, or 'all')
  <action?>     : The action to perform after build (install, install_and_run, reinstall_and_run, build) - optional

Example:
  .\android.ps1 Release apk armeabi-v7a install_and_run
#>

# Package and activity variables
$PACKAGE_NAME = "hr.envizia.letihomeplus"
$MAIN_ACTIVITY = ".LetiHomePlus"
$BUILD_TYPE = "Debug"
$SIGN_APK = "OFF"
$SIGN_AAB = "OFF"
$BUILD_APK = "OFF"
$BUILD_AAB = "OFF"
$BUILD_ALL_ABIS = "OFF"
$QT_ANDROID_ABIS = "x86"  # Default ABI

# Check for 'Release' argument
if ($build_type -eq "Release") {
    # Check for required environment variables
    $REQUIRED_VARS = @("QT_ANDROID_KEYSTORE_ALIAS", "QT_ANDROID_KEYSTORE_PATH", "QT_ANDROID_KEYSTORE_STORE_PASS", "QT_ANDROID_KEYSTORE_KEY_PASS")
    foreach ($VAR in $REQUIRED_VARS) {
        $envValue = [Environment]::GetEnvironmentVariable($VAR)
        if ([string]::IsNullOrEmpty($envValue)) {
            Write-Error "Error: Environment variable $VAR is not set."
            exit 1
        }
    }
    $BUILD_TYPE = "Release"
    $SIGN_APK = "ON"
    $SIGN_AAB = "ON"
} else {
    $BUILD_TYPE = $build_type
}

# Check for build type argument (apk, aab, both)
switch ($package_type) {
    "apk" {
        $BUILD_APK = "ON"
    }
    "aab" {
        $BUILD_AAB = "ON"
    }
    "both" {
        $BUILD_APK = "ON"
        $BUILD_AAB = "ON"
    }
}

# Check for 'all' argument or specific ABI
if ($abi -eq "all") {
    $BUILD_ALL_ABIS = "ON"
    $QT_ANDROID_ABIS = "armeabi-v7a;arm64-v8a;x86;x86_64"
} elseif (-not [string]::IsNullOrEmpty($abi)) {
    $QT_ANDROID_ABIS = $abi
}

# Always run from root dir
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location (Join-Path $scriptDir "..")

# Create build directory
if (-not (Test-Path "build_android")) {
    New-Item -ItemType Directory -Path "build_android" | Out-Null
}
Set-Location "build_android"

$qtPath = "C:\Qt\6.5.3\android_x86\bin\qt-cmake.bat"
$androidSdkRoot = "C:\Android"
$androidNdkRoot = "C:\Android\ndk\27.2.12479018"

Write-Host "Building with the following configuration:"
Write-Host "Build Type: $BUILD_TYPE"
Write-Host "Package Type: $package_type"
Write-Host "ABI: $QT_ANDROID_ABIS"
Write-Host "Qt Path: $qtPath"
Write-Host "Android SDK: $androidSdkRoot"
Write-Host "Android NDK: $androidNdkRoot"

# Run qt-cmake
try {
    & $qtPath `
        "-DANDROID_SDK_ROOT=$androidSdkRoot" `
        "-DANDROID_NDK_ROOT=$androidNdkRoot" `
        "-DCMAKE_BUILD_TYPE=$BUILD_TYPE" `
        "-DQT_ANDROID_SIGN_APK=$SIGN_APK" `
        "-DQT_ANDROID_SIGN_AAB=$SIGN_AAB" `
        "-DQT_ANDROID_BUILD_ALL_ABIS=$BUILD_ALL_ABIS" `
        "-DQT_ANDROID_ABIS=$QT_ANDROID_ABIS" `
        "-GNinja" `
        ".."

    if ($LASTEXITCODE -ne 0) {
        Write-Error "qt-cmake failed with exit code $LASTEXITCODE"
        exit 1
    }
} catch {
    Write-Error "Failed to run qt-cmake: $_"
    exit 1
}

# Build APK if requested
if ($BUILD_APK -eq "ON") {
    Write-Host "Building APK..."
    cmake --build . --target apk
    if ($LASTEXITCODE -ne 0) {
        Write-Error "APK build failed with exit code $LASTEXITCODE"
        exit 1
    }
}

# Build AAB if requested
if ($BUILD_AAB -eq "ON") {
    Write-Host "Building AAB..."
    cmake --build . --target aab
    if ($LASTEXITCODE -ne 0) {
        Write-Error "AAB build failed with exit code $LASTEXITCODE"
        exit 1
    }
}

# Set APK_FILE and AAB_FILE based on build type
if ($BUILD_TYPE -eq "Release") {
    $APK_FILE = "android-build/build/outputs/apk/release/android-build-release-signed.apk"
    $AAB_FILE = "android-build/build/outputs/bundle/release/android-build-release.aab"
} else {
    $APK_FILE = "android-build/build/outputs/apk/debug/android-build-debug.apk"
    $AAB_FILE = "android-build/build/outputs/bundle/debug/android-build-debug.aab"
}

# Handle post-build actions
switch ($action) {
    "install" {
        Write-Host "Installing APK..."
        adb install $APK_FILE
    }
    "install_and_run" {
        Write-Host "Installing and running APK..."
        adb install $APK_FILE
        adb shell am force-stop $PACKAGE_NAME
        adb shell am start -n "$PACKAGE_NAME/$MAIN_ACTIVITY"
    }
    "reinstall_and_run" {
        Write-Host "Uninstalling, reinstalling and running APK..."
        adb uninstall $PACKAGE_NAME
        adb install $APK_FILE
        adb shell am force-stop $PACKAGE_NAME
        adb shell am start -n "$PACKAGE_NAME/$MAIN_ACTIVITY"
    }
    "build" {
        Write-Host "Copying build artifacts..."
        # Extract version from CMakeLists.txt
        $cmakeContent = Get-Content "../CMakeLists.txt" -Raw
        $versionMatch = [regex]::Match($cmakeContent, 'QT_ANDROID_VERSION_NAME "([0-9.]+)"')
        if ($versionMatch.Success) {
            $version = $versionMatch.Groups[1].Value
            if (Test-Path $APK_FILE) {
                Copy-Item $APK_FILE "LetiHome-$version.apk"
                Write-Host "Copied APK to LetiHome-$version.apk"
            }
            if (Test-Path $AAB_FILE) {
                Copy-Item $AAB_FILE "LetiHome-$version.aab"
                Write-Host "Copied AAB to LetiHome-$version.aab"
            }
        } else {
            Write-Warning "Could not extract version from CMakeLists.txt"
        }
    }
}

Write-Host "Android build script completed successfully!"
