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

bentoo template --tools tool_runners/tools_python.toml reality-check/python/benchmark > reality-check/python/benchmark/runs.toml
bentoo bench --tools tool_runners/tools_python.toml --runs reality-check/python/benchmark/runs.toml --timeout 3600 reality-check-python-output
./scripts/draw-benchamrk-summary-charts.py reality-check-python-output reality-check-python reality_check_python
