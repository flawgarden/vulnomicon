#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BASE_DIR="$(cd "$SCRIPT_DIR"/.. && pwd)"
ARCH=$(uname -m)

cd "$BASE_DIR" || exit;

UPDATE_BENTOO="false"

for OPT in "$@"; do
  if [[ "$OPT" = *"--update"* ]]; then
      UPDATE_BENTOO="true"
      shift 1
  fi
done

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

if [[ "$UPDATE_BENTOO" = "true" ]]; then
    wget https://github.com/flawgarden/bentoo/releases/download/latest/$ARCHIVE_NAME
    tar -xf $ARCHIVE_NAME
    rm $ARCHIVE_NAME

    # Download tool runners
    wget https://github.com/flawgarden/bentoo/releases/download/latest/tool_runners.tar.gz
    tar -xf tool_runners.tar.gz
    rm tool_runners.tar.gz
else
    wget https://github.com/flawgarden/bentoo/releases/download/v0.0.1/$ARCHIVE_NAME
    tar -xf $ARCHIVE_NAME
    rm $ARCHIVE_NAME
fi
