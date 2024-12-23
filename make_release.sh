#!/bin/sh

command -v git >/dev/null 2>&1 || { echo >&2 "'git' is required but not installed. Aborting."; exit 1; }
command -v python >/dev/null 2>&1 || { echo >&2 "'python' is required but not installed. Aborting."; exit 1; }

version=$1

changelog_file=CHANGELOG.md
release_file=RELEASE
version_format="$(date +"%Y-%m-%d"), Version $version"

if [ -z $version ]
then
    echo "version invalid" >&2
    echo "usage: make_release.sh <version>" >&2
    exit 1
fi

# always run from root dir
cd "$( dirname "${BASH_SOURCE[0]}" )"

if [ ! -f RELEASE ]; then echo "'RELEASE' file not found. Aborting."; exit 1;  fi

current_version=$(cat RELEASE)

echo "current version: $current_version"

if [ "$current_version" = "$version" ]
then
    echo "Version not changed. Aborting."
    exit 1
fi
profile=$(find . -name LetiHome.pro -type f)
if [ ! -f $profile ]; then echo "'LetiHome.pro' file not found. Aborting."; exit 1;  fi

#### --------------
#### ANDROID
#### --------------

update_android()
{
    echo ": updating android version"

    # update android version name
    sed -i.bak "s/ANDROID_VERSION_NAME = [^ ]*/ANDROID_VERSION_NAME = \"$version\"/" $profile

    # increment android version code
    version_code=$(grep -F ANDROID_VERSION_CODE $profile | sed 's/.*ANDROID_VERSION_CODE//' | sed 's/[^0-9]*//g')
    version_code_target=$((version_code + 1))

    sed -i.bak "s/ANDROID_VERSION_CODE.*/ANDROID_VERSION_CODE = \"$version_code_target\"/" $profile

    echo ":: version code increased from: $version_code to: $version_code_target"
    echo ": android version updated"
}

#### --------------
#### RELEASE file
#### --------------

make_release_file()
{
    echo $version > $release_file
    echo "version updated to $version"
}

#### --------------
#### CHANGELOG file
#### --------------

make_changelog_file()
{
tempfile="changelog.tmp"

cat > $tempfile <<- EOF
## $version_format

### Notable changes

#### The following significant changes have been made since the previous LetiHome $current_version release.

<list notable features manually here>

### commits

EOF

    git log $current_version..HEAD --oneline --format=" - %h %s " | \
        perl -pe 's/([a-z0-9]{7})/[$1](https:\/\/github.com\/qaap\/LetiHome\/commit\/$1)/' | \
        perl -pe 's/#.*$//' | perl -pe 's/ *$//' \
        >> $tempfile

    echo "" >> $tempfile

    cat $changelog_file >> $tempfile
    mv $tempfile $changelog_file

    ${EDITOR:-vim} $changelog_file
}

#### --------------
#### COMMIT RELEASE
#### --------------

commit_release()
{
    git reset HEAD .
    git add $android_manifest $release_file $changelog_file
    git commit -sm "$version_format"
    git tag -a "$version" -m "$version_format"
}

update_android && make_release_file && make_changelog_file && commit_release
