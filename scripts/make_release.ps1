param(
    [Parameter(Mandatory=$true)]
    [string]$version
)

# Check if git is available
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "'git' is required but not installed. Aborting."
    exit 1
}

$changelog_file = "CHANGELOG.md"
$release_file = "RELEASE"
$version_format = "$(Get-Date -Format 'yyyy-MM-dd'), Version $version"

if ([string]::IsNullOrEmpty($version)) {
    Write-Error "version invalid"
    Write-Error "usage: make_release.ps1 <version>"
    exit 1
}

# Always run from root dir
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location (Join-Path $scriptDir "..")

if (-not (Test-Path $release_file)) {
    Write-Error "'RELEASE' file not found. Aborting."
    exit 1
}

$current_version = Get-Content $release_file -Raw | ForEach-Object { $_.Trim() }
Write-Host "current version: $current_version"

if ($current_version -eq $version) {
    Write-Error "Version not changed. Aborting."
    exit 1
}

$profile = Get-ChildItem -Path "." -Name "CMakeLists.txt" -Recurse -File | ForEach-Object { Join-Path (Get-Location) $_ } | Select-Object -First 1
if (-not $profile -or -not (Test-Path $profile)) {
    Write-Error "'CMakeLists.txt' file not found. Aborting."
    Write-Host "Current directory: $(Get-Location)"
    Write-Host "Available files: $(Get-ChildItem -Recurse -File | Select-Object -First 10 | ForEach-Object Name)"
    exit 1
}
Write-Host "Found CMakeLists.txt at: $profile"

#### --------------
#### ANDROID
#### --------------
function Update-Android {
    Write-Host ": updating android version"

    # Update android version name
    $content = Get-Content $profile
    $content = $content -replace 'ANDROID_VERSION_NAME [^ ]*', "ANDROID_VERSION_NAME `"$version`""
    $content | Set-Content $profile

    # Increment android version code
    $version_code_line = $content | Select-String "ANDROID_VERSION_CODE"
    if ($version_code_line) {
        $version_code = [regex]::Match($version_code_line.Line, '\d+').Value
        $version_code_target = [int]$version_code + 1
        $content = $content -replace 'ANDROID_VERSION_CODE.*', "ANDROID_VERSION_CODE $version_code_target"
        $content | Set-Content $profile
        Write-Host ":: version code increased from: $version_code to: $version_code_target"
    }

    Write-Host ": android version updated"
}

#### --------------
#### RELEASE file
#### --------------
function Make-ReleaseFile {
    $version | Set-Content $release_file
    Write-Host "version updated to $version"
}

#### --------------
#### CHANGELOG file
#### --------------
function Make-ChangelogFile {
    $tempfile = "changelog.tmp"

    $changelog_header = @"
## $version_format
### Notable changes
#### The following significant changes have been made since the previous LetiHome $current_version release.
<list notable features manually here>
### commits
"@

    $changelog_header | Set-Content $tempfile

    # Get git log and format it - git already returns separate lines
    $git_log = git log "$current_version..HEAD" --oneline --format=" - %h %s "

    foreach ($line in $git_log) {
        if (![string]::IsNullOrWhiteSpace($line)) {
            # Convert hash to markdown link - only match hash at the beginning after " - "
            $formatted_line = $line -replace '^ - ([a-f0-9]{7})', ' - [$1](https://github.com/pkoretic/LetiHome/commit/$1)'
            # Remove # comments and everything after
            $formatted_line = ($formatted_line -split '#')[0]
            # Trim trailing spaces
            $formatted_line = $formatted_line.TrimEnd()

            # Add each line to the temp file
            Add-Content -Path $tempfile -Value $formatted_line
        }
    }
    "" | Add-Content $tempfile

    if (Test-Path $changelog_file) {
        Get-Content $changelog_file | Add-Content $tempfile
    }

    Move-Item $tempfile $changelog_file -Force

    # Open editor (try common editors)
    $editor = $env:EDITOR
    if (-not $editor) {
        $editors = @("vim", "code", "notepad++", "notepad")
        foreach ($ed in $editors) {
            if (Get-Command $ed -ErrorAction SilentlyContinue) {
                $editor = $ed
                break
            }
        }
        if (-not $editor) { $editor = "notepad" }
    }

    # Start editor and wait for it to finish
    $editorProcess = Start-Process $editor -ArgumentList $changelog_file -Wait -PassThru

    # Check if editor exited successfully
    if ($editorProcess.ExitCode -eq 0 -or $null -eq $editorProcess.ExitCode) {
        Write-Host "Editor closed successfully. Continuing with commit..."
    } else {
        Write-Host "Editor exited with code $($editorProcess.ExitCode). Press Enter to continue anyway or Ctrl+C to abort..."
        Read-Host
    }
}

#### --------------
#### COMMIT RELEASE
#### --------------
function Commit-Release {
    git reset HEAD .
    git add $release_file $profile $changelog_file
    git commit -sm "$version_format"
    git tag -a "$version" -m "$version_format"
}

# Execute all functions
try {
    Update-Android
    Make-ReleaseFile
    Make-ChangelogFile
    Commit-Release
    Write-Host "Release $version created successfully!"
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}
