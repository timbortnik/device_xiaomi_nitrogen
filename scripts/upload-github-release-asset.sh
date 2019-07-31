#!/bin/bash

# calling convention
# upload-github-release-asset.sh "TOKEN" "OWNER" "REPOSITORY" "TAG" "FILENAME"

# Check dependencies
set -e
xargs=$(which gxargs || which xargs)

# Validate settings
[ "$TRACE" ] && set -x

# Name the command line arguments
github_api_token="$1"
owner="$2"
repo="$3"
tag="$4"
filename="$5"

# Define variables
GH_API="https://api.github.com"
GH_REPO="$GH_API/repos/$owner/$repo"
GH_TAGS="$GH_REPO/releases/tags/$tag"
AUTH="Authorization: token $github_api_token"
WGET_ARGS="--content-disposition --auth-no-challenge --no-cookie"
CURL_ARGS="-LJO#"

# Fall back to the latest tag if required
if [[ "$tag" == 'LATEST' ]]; then
  GH_TAGS="$GH_REPO/releases/latest"
fi

# Validate token
curl -o /dev/null -sH "$AUTH" $GH_REPO || { echo "Error: Invalid repo, token or network issue!";  exit 1; }

# Read asset tags
response=$(curl -sH "$AUTH" $GH_TAGS)

# Get ID of the asset based on given filename
eval $(echo "$response" | grep -m 1 "id.:" | grep -w id | tr : = | tr -cd '[[:alnum:]]=')
[ "$id" ] || { echo "Error: Failed to get release id for tag: $tag"; echo "$response" | awk 'length($0)<100' >&2; exit 1; }

# Upload asset
echo "Uploading asset... "
GH_ASSET="https://uploads.github.com/repos/$owner/$repo/releases/$id/assets?name=$(basename $filename)"
curl "$GITHUB_OAUTH_BASIC" --data-binary @"$filename" -H "Authorization: token $github_api_token" -H "Content-Type: application/octet-stream" $GH_ASSET
