#!/bin/bash
set -euo pipefail

command -v git >/dev/null 2>&1 || { echo "'git' is required but not installed. Aborting." >&2; exit 1; }

version="$1"

# Validate semver format
if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version '$version'. Expected format: X.Y.Z" >&2
    echo "Usage: make_release.sh <version>" >&2
    exit 1
fi

version_format="$(date +"%Y-%m-%d"), Version $version"

# Always run from project root
cd "$(dirname "${BASH_SOURCE[0]}")/.."

cmake_file="./CMakeLists.txt"
if [ ! -f "$cmake_file" ]; then
    echo "'CMakeLists.txt' not found in project root. Aborting." >&2; exit 1
fi

# Get current version from the latest git tag
current_version=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
echo "current version: ${current_version:-(none)}"

if [ "$current_version" = "$version" ]; then
    echo "Version not changed. Aborting." >&2; exit 1
fi

#### --------------
#### UPDATE VERSION
#### --------------
echo ": updating android version"

# Update android version name
sed -i.bak "s/ANDROID_VERSION_NAME [^ ]*/ANDROID_VERSION_NAME \"$version\"/" "$cmake_file"

# Increment android version code
version_code=$(grep -oP 'ANDROID_VERSION_CODE\s+\K\d+' "$cmake_file")
version_code_target=$((version_code + 1))

sed -i.bak "s/ANDROID_VERSION_CODE[[:space:]]*[0-9]*/ANDROID_VERSION_CODE $version_code_target/" "$cmake_file"

rm -f "${cmake_file}.bak"

echo ":: version code increased from: $version_code to: $version_code_target"
echo ": android version updated"

#### --------------
#### COMMIT & TAG
#### --------------
git reset HEAD .
git add "$cmake_file"
git commit -m "$version_format"
git tag -a "$version" -m "$version_format"

echo ""
echo "Release $version created successfully!"
echo "Push with:  git push && git push origin $version"
