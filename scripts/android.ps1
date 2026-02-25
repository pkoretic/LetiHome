[CmdletBinding()]
param(
    # Target ABI for this build.
    [ValidateSet("armeabi-v7a", "arm64-v8a", "x86", "x86_64")]
    [string]$Abi = "x86",

    # Post-build action.
    [ValidateSet("install", "run", "reinstall")]
    [string]$Action,

    # Skip cmake configure when the build directory already has a CMakeCache.
    [switch]$SkipConfigure,

    # Delete the build directory before building (forces a full rebuild).
    [switch]$Clean,

    # Override: path to qt-cmake.bat  (default: C:\Qt\6.5.3\android_x86\bin\qt-cmake.bat)
    [string]$QtCmake = "C:\Qt\6.5.3\android_x86\bin\qt-cmake.bat",

    # Override: Android SDK root  (default: C:\Android)
    [string]$SdkRoot = "C:\Android",

    # Override: Android NDK root  (default: C:\Android\ndk\27.2.12479018)
    [string]$NdkRoot = "C:\Android\ndk\27.2.12479018"
)

<#
.SYNOPSIS
    Builds a debug APK of LetiHome+ for a single Android ABI.

.DESCRIPTION
    Configures, compiles and packages a debug APK using Qt & CMake/Ninja.
    Optionally installs / launches on a connected device via adb.
    Release builds and AAB packaging are handled by CI (GitHub Actions).

.EXAMPLE
    .\android.ps1
    Quick debug APK for x86 (emulator default).

.EXAMPLE
    .\android.ps1 -Abi arm64-v8a -Action run
    Debug APK on arm64, install & launch on device.

.EXAMPLE
    .\android.ps1 -Abi arm64-v8a -SkipConfigure
    Rebuild without re-running cmake configure (faster iteration).

.EXAMPLE
    .\android.ps1 -Abi arm64-v8a -Clean
    Clean build from scratch.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$timer = [System.Diagnostics.Stopwatch]::StartNew()

# ── Constants ────────────────────────────────────────────────────────────────
$PACKAGE_NAME  = "hr.envizia.letihomeplus"
$MAIN_ACTIVITY = ".LetiHomePlus"

# ── Paths ────────────────────────────────────────────────────────────────────
$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$projectRoot = (Resolve-Path (Join-Path $scriptDir "..")).Path
$buildDir    = Join-Path $projectRoot "build_android"

# ── Extract version from CMakeLists.txt ──────────────────────────────────────
$cmakeContent = Get-Content (Join-Path $projectRoot "CMakeLists.txt") -Raw
$versionMatch = [regex]::Match($cmakeContent, 'QT_ANDROID_VERSION_NAME\s+"([0-9.]+)"')
$version      = if ($versionMatch.Success) { $versionMatch.Groups[1].Value } else { "unknown" }

# ── Validate tools ───────────────────────────────────────────────────────────
if (-not (Test-Path $QtCmake)) {
    Write-Error "qt-cmake not found at: $QtCmake"
    exit 1
}
if (-not (Test-Path $SdkRoot)) {
    Write-Error "Android SDK not found at: $SdkRoot"
    exit 1
}
if (-not (Test-Path $NdkRoot)) {
    Write-Error "Android NDK not found at: $NdkRoot"
    exit 1
}
if ($Action -and -not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Write-Error "'adb' is required for -Action $Action but not found in PATH."
    exit 1
}

# ── Clean ────────────────────────────────────────────────────────────────────
if ($Clean -and (Test-Path $buildDir)) {
    Write-Host "Cleaning build directory..."
    Remove-Item $buildDir -Recurse -Force
}

New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

# ── Print configuration ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "┌─ LetiHome+ Debug APK (v$version) ─────────────────────────"
Write-Host "│  ABI        : $Abi"
Write-Host "│  Action     : $(if ($Action) { $Action } else { '(none)' })"
Write-Host "│  Qt cmake   : $QtCmake"
Write-Host "│  SDK        : $SdkRoot"
Write-Host "│  NDK        : $NdkRoot"
Write-Host "└──────────────────────────────────────────────────────"
Write-Host ""

# ── Configure (qt-cmake) ────────────────────────────────────────────────────
$cmakeCache = Join-Path $buildDir "CMakeCache.txt"

if ($SkipConfigure -and (Test-Path $cmakeCache)) {
    Write-Host "Skipping cmake configure (-SkipConfigure, CMakeCache exists)."
} else {
    Write-Host "Running qt-cmake configure..."
    $cmakeArgs = @(
        "-DANDROID_SDK_ROOT=$SdkRoot",
        "-DANDROID_NDK_ROOT=$NdkRoot",
        "-DCMAKE_BUILD_TYPE=Debug",
        "-DQT_ANDROID_BUILD_ALL_ABIS=OFF",
        "-DQT_ANDROID_ABIS=$Abi",
        "-GNinja"
    )
    # If the FetchContent source was already downloaded, skip network access
    $fetchDir = Join-Path $buildDir "_deps/android_openssl-src"
    if (Test-Path $fetchDir) {
        $cmakeArgs += "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
    }
    $cmakeArgs += @("-S", $projectRoot, "-B", $buildDir)

    & $QtCmake @cmakeArgs

    if ($LASTEXITCODE -ne 0) {
        Write-Error "qt-cmake configure failed (exit code $LASTEXITCODE)."
        exit 1
    }
}

# ── Gradle optimizations ────────────────────────────────────────────────────
if (-not $env:GRADLE_OPTS) {
    $env:GRADLE_OPTS = "-Dorg.gradle.daemon=true -Dorg.gradle.parallel=true -Dorg.gradle.caching=true -Xmx2g"
}

# ── Remove stale Gradle lock files ──────────────────────────────────────────
$gradleDir = Join-Path $buildDir "android-build/.gradle"
if (Test-Path $gradleDir) {
    Get-ChildItem $gradleDir -Recurse -Filter "*.lock" -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

# ── Build APK ────────────────────────────────────────────────────────────────
Write-Host "Building debug APK ($Abi)..."
cmake --build $buildDir --target apk --parallel
if ($LASTEXITCODE -ne 0) {
    Write-Error "APK build failed (exit code $LASTEXITCODE)."
    exit 1
}

# ── Resolve APK path ────────────────────────────────────────────────────────
$APK_FILE = Join-Path $buildDir "android-build/build/outputs/apk/debug/android-build-debug.apk"

if (-not (Test-Path $APK_FILE)) {
    Write-Error "APK not found at expected path: $APK_FILE"
    exit 1
}

$sizeMB = "{0:N1} MB" -f ((Get-Item $APK_FILE).Length / 1MB)
Write-Host "APK ready: $APK_FILE ($sizeMB)"

# ── Post-build actions ──────────────────────────────────────────────────────
switch ($Action) {
    "install" {
        Write-Host "Installing APK..."
        adb install $APK_FILE
    }
    "run" {
        Write-Host "Installing and launching..."
        adb install $APK_FILE
        adb shell am force-stop $PACKAGE_NAME
        adb shell am start -n "$PACKAGE_NAME/$MAIN_ACTIVITY"
    }
    "reinstall" {
        Write-Host "Reinstalling and launching..."
        adb uninstall $PACKAGE_NAME 2>$null
        adb install $APK_FILE
        adb shell am force-stop $PACKAGE_NAME
        adb shell am start -n "$PACKAGE_NAME/$MAIN_ACTIVITY"
    }
}

# ── Done ─────────────────────────────────────────────────────────────────────
$timer.Stop()
$elapsed = $timer.Elapsed.ToString("mm\:ss")
Write-Host ""
Write-Host "Build completed in $elapsed." -ForegroundColor Green
