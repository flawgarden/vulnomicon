#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BASE_DIR="$(cd "$SCRIPT_DIR"/.. && pwd)"
ARCH=$(uname -m)

cd "$BASE_DIR" || exit;

if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ "$ARCH" == "x86_64" ]]; then
        echo "Downloading bentoo binary for Mac OS / x86_64"
        ARCHIVE_NAME=bentoo-x86-macos.tar.gz
    elif [[ "$ARCH" == "arm64" ]]; then
        echo "Downloading bentoo binary for Mac OS / ARM64"
        ARCHIVE_NAME=bentoo-arm-macos.tar.gz
    else
        echo "OS/CPU Architecture unsupported"
        exit 1
    fi
elif [[ "$OSTYPE" == "linux"* ]]; then
    if [[ "$ARCH" == "x86_64" ]]; then
        echo "Downloading bentoo binary for Linux / x86_64"
        ARCHIVE_NAME=bentoo-x86-linux.tar.gz
    else
        echo "OS/CPU Architecture unsupported"
        exit 1
    fi
else
    echo "OS/CPU Architecture unsupported"
    exit 1
fi

wget https://github.com/flawgarden/bentoo/releases/download/latest/$ARCHIVE_NAME
tar -xf $ARCHIVE_NAME
rm $ARCHIVE_NAME

# Download tool runners
wget https://github.com/flawgarden/bentoo/releases/download/latest/tool_runners.tar.gz
tar -xf tool_runners.tar.gz
rm tool_runners.tar.gz
