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

bentoo template --tools tool_runners/tools_go.toml reality-check/go/benchmark > reality-check/go/benchmark/runs.toml
bentoo bench --tools tool_runners/tools_go.toml --runs reality-check/go/benchmark/runs.toml --timeout 3600 reality-check-go-output
./scripts/draw-benchamrk-summary-charts.py reality-check-go-output reality-check-go reality_check_go

