#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BASE_DIR="$(cd "$SCRIPT_DIR"/../../../../ && pwd)"

cd "$BASE_DIR" || exit;

if [ ! -f "bentoo" ]; then
    echo "Please run bentoo.sh beforehand"
    exit 1
fi

if [ ! -d "tool_runners" ]; then
    echo "Please run bentoo.sh beforehand"
    exit 1
fi

if ! docker ps -a &> /dev/null
then
    echo "Please run docker daemon beforehand"
    exit 1
fi

PATH=$PATH:$(pwd)

bentoo template --tools tool_runners/tools_python.toml sast-rules/python > sast-rules/python/runs.toml
bentoo bench --tools tool_runners/tools_python.toml --runs sast-rules/python/runs.toml sast-rules-python-output
./scripts/draw-benchamrk-summary-charts.py sast-rules-python-output sast-rules-python sast_rules_python
