param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Check if git is available
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "'git' is required but not installed. Aborting."
    exit 1
}

$version_format = "$(Get-Date -Format 'yyyy-MM-dd'), Version $version"

# Always run from root dir
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location (Join-Path $scriptDir "..")

$cmakeFile = Join-Path (Get-Location) "CMakeLists.txt"
if (-not (Test-Path $cmakeFile)) {
    Write-Error "'CMakeLists.txt' not found in project root. Aborting."
    exit 1
}

# Get current version from the latest git tag
$current_version = git describe --tags --abbrev=0 2>$null
Write-Host "current version: $(if ($current_version) { $current_version } else { '(none)' })"

if ($current_version -eq $version) {
    Write-Error "Version not changed. Aborting."
    exit 1
}

#### --------------
#### UPDATE VERSION
#### --------------
Write-Host ": updating android version"

$content = Get-Content $cmakeFile

# Update android version name
$content = $content -replace 'ANDROID_VERSION_NAME [^ ]*', "ANDROID_VERSION_NAME `"$version`""

# Increment android version code
$version_code_line = $content | Select-String "ANDROID_VERSION_CODE"
if ($version_code_line) {
    $version_code = [regex]::Match($version_code_line.Line, 'ANDROID_VERSION_CODE\s+(\d+)').Groups[1].Value
    $version_code_target = [int]$version_code + 1
    $content = $content -replace 'ANDROID_VERSION_CODE\s+\d+', "ANDROID_VERSION_CODE $version_code_target"
    Write-Host ":: version code increased from: $version_code to: $version_code_target"
}

$content | Set-Content $cmakeFile
Write-Host ": android version updated"

#### --------------
#### COMMIT & TAG
#### --------------
git reset HEAD .
git add $cmakeFile
git commit -m "$version_format"
git tag -a "$version" -m "$version_format"

Write-Host ""
Write-Host "Release $version created successfully!" -ForegroundColor Green
Write-Host "Push with:  git push && git push origin $version" -ForegroundColor Yellow
