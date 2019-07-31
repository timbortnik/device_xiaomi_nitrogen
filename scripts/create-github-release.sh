#!/bin/bash

# calling convention
# create-github-release.sh "TOKEN" "OWNER" "REPOSITORY" "BRANCH" "TAG" "TITLE" "BODY"

# Name the command line arguments
TOKEN="$1"
OWNER="$2"
REPOSITORY="$3"
BRANCH="$4"
TAG="$5"
TITLE="$6"
BODY="$7"

# Create the release
API_JSON=$(printf '{"tag_name": "%s","target_commitish": "%s","name": "%s","body": "%s","draft": false,"prerelease": false}' "$TAG" "$BRANCH" "$TITLE" "$BODY")
curl --data "$API_JSON" https://api.github.com/repos/$OWNER/$REPOSITORY/releases?access_token=$TOKEN
