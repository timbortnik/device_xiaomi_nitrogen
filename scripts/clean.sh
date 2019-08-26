#!/bin/bash

# Get the current script location
SCRIPT=$(readlink -f "$0")

# Get the scripts folder location
SCRIPTPATH=$(dirname "$SCRIPT")

# Navigate to the scripts folder
cd "$SCRIPTPATH"

# Navigate to the build system root
cd "../../../.."

# Wipe out the package cache
rm -rf out/target/product/*/vendor 2>/dev/null
rm -rf out/target/product/*/system 2>/dev/null
rm -rf out/target/product/*/obj/ETC 2>/dev/null
rm -rf out/target/product/*/obj/PACKAGING 2>/dev/null

# Remove old builds to conserve space
rm -f out/target/product/*/*.zip*
