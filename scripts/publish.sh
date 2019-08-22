#!/bin/bash

# Note: Ensure you've exported your Github Token in your .bashrc file like this before using this script!
# export GITHUB_TOKEN=...

# Get the current script location
SCRIPT=$(readlink -f "$0")

# Get the scripts folder location
SCRIPTPATH=$(dirname "$SCRIPT")

# Navigate to the scripts folder (which should be inside the git repository path)
cd "$SCRIPTPATH"

# Determine the repository URL, owner, name and branch
URL=`git config --get remote.origin.url`
OWNER=`echo $URL | rev | cut "-d." -f2 | cut "-d:" -f1 | cut "-d/" -f2 | rev`
REPOSITORY=`echo $URL | rev | cut "-d." -f2 | cut "-d:" -f1 | cut "-d/" -f1 | rev`
BRANCH=`git branch | grep "*" | cut "-d " -f2`

# Navigate to the build system root
cd "../../../.."

# Navigate into the build directory
cd out/target/product/*

# Determine the build's file name
BUILD_NAME=`ls *.zip | grep -v md5`

# Determine the build's file size
BUILD_SIZE=`stat --printf="%s" "$BUILD_NAME"`

# Determine the build's time stamp
BUILD_TIMESTAMP=`cat system/build.prop | grep ro.build.date.utc | cut "-d=" -f2`

# Grab the crDroid mod version
MOD_VERSION=`cat system/build.prop | grep ro.modversion | cut "-d=" -f2`

# Generate a build ID
BUILD_ID=`hexdump -n 32 -e '8/4 "%08X" 1 "\n"' /dev/random`

# Generate a readable build date ("30. July 2019")
BUILD_READABLE_DATE=`LANG=en_us_88591 date -d "@$BUILD_TIMESTAMP" "+%d. %B %Y"`

# Generate a short readable build date ("20190730")
BUILD_SHORT_READABLE_DATE=`LANG=en_us_88591 date -d "@$BUILD_TIMESTAMP" "+%Y%m%d"`

# Generate a tag, title & default body markdown block
TAG="$BUILD_SHORT_READABLE_DATE-$BRANCH"
TITLE="$BUILD_READABLE_DATE $BRANCH Build"
BODY="# Changelog\n* Pulled in upstream changes"

# crDroid needs a regex compatible filename for OTA to work properly
mv "$BUILD_NAME" "crDroidAndroid-9.0-$BUILD_SHORT_READABLE_DATE-nitrogen-v$MOD_VERSION.zip"
BUILD_NAME=`ls *.zip | grep -v md5`

# Create a github release for this build
"$SCRIPTPATH/create-github-release.sh" "$GITHUB_TOKEN" "$OWNER" "$REPOSITORY" "$BRANCH" "$TAG" "$TITLE" "$BODY"

# Attach the build asset to the release
"$SCRIPTPATH/upload-github-release-asset.sh" "$GITHUB_TOKEN" "$OWNER" "$REPOSITORY" "$TAG" "$BUILD_NAME"

# Generate the asset direct link
BUILD_URL="https://github.com/$OWNER/$REPOSITORY/releases/download/$TAG/$BUILD_NAME"

# Return to the scripts directory
cd "$SCRIPTPATH"

# Navigate into the device tree directory
cd ..

# Update the OTA updatelist file
echo '<?xml version="1.0" encoding="UTF-8"?>' > updatelist.xml
echo '<OTA xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="ota.xsd">' >> updatelist.xml
echo '    <manufacturer id="Xiaomi">' >> updatelist.xml
echo '        <nitrogen>' >> updatelist.xml
echo -n '            <maintainer>' >> updatelist.xml
echo -n "$OWNER" >> updatelist.xml
echo '</maintainer>' >> updatelist.xml
echo '            <devicename>Mi Max 3</devicename>' >> updatelist.xml
echo -n '            <filename>' >> updatelist.xml
echo -n "${BUILD_NAME%.*}" >> updatelist.xml
echo '</filename>' >> updatelist.xml
echo '            <buildtype>Weekly</buildtype>' >> updatelist.xml
echo -n '            <download>' >> updatelist.xml
echo -n "$BUILD_URL" >> updatelist.xml
echo '</download>' >> updatelist.xml
echo '            <changelog>https://github.com/Black-Seraph/device_xiaomi_nitrogen/commits/pie-crdroid</changelog>' >> updatelist.xml
echo '            <gapps>https://opengapps.org</gapps>' >> updatelist.xml
echo '            <forum>https://patreon.com/blackseraph</forum>' >> updatelist.xml
echo '            <paypal>https://ko-fi.com/blackseraph</paypal>' >> updatelist.xml
echo '        </nitrogen>' >> updatelist.xml
echo '    </manufacturer>' >> updatelist.xml
echo '</OTA>' >> updatelist.xml

# Add, commit & push the updated updatelist file
git add updatelist.xml
git commit -m "nitrogen: OTA auto-update"
git push
