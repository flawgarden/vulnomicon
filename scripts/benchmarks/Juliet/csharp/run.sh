#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BASE_DIR="$(cd "$SCRIPT_DIR"/../../../../ && pwd)"

cd "$BASE_DIR" || exit;

if [ ! -f "bentoo" ]; then
    echo "Please run bentoo.sh beforehand"
fi

if [ ! -d "tool_runners" ]; then
    echo "Please run bentoo.sh beforehand"
fi

PATH=$PATH:$(pwd)

bentoo template --tools tool_runners/tools_csharp.toml JulietCSharp > JulietCSharp/runs.toml
bentoo bench --tools tool_runners/tools_csharp.toml --runs JulietCSharp/runs.toml --timeout 1200 JulietCSharp-output
./scripts/draw-benchamrk-summary-charts.py JulietCSharp-output JulietCSharp juliet_csharp
