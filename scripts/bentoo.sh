#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BASE_DIR="$(cd $SCRIPT_DIR/.. && pwd)"

cd $BASE_DIR;

wget https://github.com/flawgarden/bentoo/releases/download/latest/bentoo.tar.gz
wget https://github.com/flawgarden/bentoo/releases/download/latest/tool_runners.tar.gz

tar -xf bentoo.tar.gz
tar -xf tool_runners.tar.gz

rm bentoo.tar.gz tool_runners.tar.gz

