#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BASE_DIR="$(cd "$SCRIPT_DIR"/.. && pwd)"

cd "$BASE_DIR" || exit;

wget https://github.com/flawgarden/bentoo/releases/download/latest/bentoo-x86-linux.tar.gz
wget https://github.com/flawgarden/bentoo/releases/download/latest/tool_runners.tar.gz

tar -xf bentoo-x86-linux.tar.gz
tar -xf tool_runners.tar.gz

rm bentoo-x86-linux.tar.gz tool_runners.tar.gz

