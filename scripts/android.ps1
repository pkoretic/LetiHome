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

    # Override: path to qt-cmake.bat  (default: auto-selected per ABI)
    [string]$QtCmake = "",

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
# use separate build tree for each ABI to avoid rebuilding unintended platforms
$buildDir    = Join-Path $projectRoot "build_android\$Abi"

# ── Extract version from CMakeLists.txt ──────────────────────────────────────
$cmakeContent = Get-Content (Join-Path $projectRoot "CMakeLists.txt") -Raw
$versionMatch = [regex]::Match($cmakeContent, 'QT_ANDROID_VERSION_NAME\s+"([0-9.]+)"')
$version      = if ($versionMatch.Success) { $versionMatch.Groups[1].Value } else { "unknown" }

# if user didn't specify QtCmake choose appropriate Qt for the ABI
if (-not $QtCmake) {
    $qtRoot = "C:\Qt\6.5.3"
    switch ($Abi) {
        'armeabi-v7a' { $sub = 'android_armv7' }
        'arm64-v8a'   { $sub = 'android_arm64_v8a' }
        'x86'         { $sub = 'android_x86' }
        'x86_64'      { $sub = 'android_x86_64' }
        default       { $sub = 'android_x86' }
    }
    $QtCmake = Join-Path $qtRoot "$sub\bin\qt-cmake.bat"
}

# ensure selected Qt installation actually contains the ABI plugin
# compute Qt root by removing \bin\qt-cmake.bat
$qtRootDir = Split-Path $QtCmake -Parent                     # <...>\bin
$qtRootDir = Split-Path $qtRootDir -Parent                   # <...>\<abi>

# ── Validate other tools ───────────────────────────────────────────────────────
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

# ensure build directory exists for this ABI
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

# ── Print configuration ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "┌─ LetiHome+ Debug APK (v$version) ───────────────────────────────────────────────────────"
Write-Host "│  ABI        : $Abi"
Write-Host "│  Action     : $(if ($Action) { $Action } else { '(none)' })"
Write-Host "│  Qt cmake   : $QtCmake"
Write-Host "│  SDK        : $SdkRoot"
Write-Host "│  NDK        : $NdkRoot"
Write-Host "└─────────────────────────────────────────────────────────────────────────────────────────"
Write-Host ""

# ── Configure (qt-cmake) ────────────────────────────────────────────────────
$cmakeCache = Join-Path $buildDir "CMakeCache.txt"

# if the cache exists but the ABI doesn't match, force reconfigure
if (Test-Path $cmakeCache) {
    $cacheText = Get-Content $cmakeCache
    if ($cacheText -match 'QT_ANDROID_ABIS:INTERNAL=(.+)') {
        $cached = $matches[1]
        if ($cached -ne $Abi) {
            Write-Host "ABI changed (was $cached, now $Abi) – deleting cache and old android_abi_builds."
            Remove-Item $cmakeCache
            $abiBuilds = Join-Path $buildDir "android_abi_builds"
            if (Test-Path $abiBuilds) { Remove-Item $abiBuilds -Recurse -Force }
        }
    }
}

if ($SkipConfigure -and (Test-Path $cmakeCache)) {
    Write-Host "Skipping cmake configure (-SkipConfigure, CMakeCache exists)."
} else {
    Write-Host "Running qt-cmake configure..."
    $cmakeArgs = @(
        "-DANDROID_SDK_ROOT=$SdkRoot",
        "-DANDROID_NDK_ROOT=$NdkRoot",
        "-DCMAKE_BUILD_TYPE=Debug",
        "-DQT_ANDROID_ABIS=$Abi",
        "-DANDROID_ABI=$Abi",
        "-DCMAKE_CXX_COMPILER_LAUNCHER=ccache",
        "-DCMAKE_C_COMPILER_LAUNCHER=ccache",
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
