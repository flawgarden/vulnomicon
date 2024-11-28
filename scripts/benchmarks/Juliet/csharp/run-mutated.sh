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

bentoo template --tools tool_runners/tools_csharp_juliet_mutated.toml JulietCSharp-mutated > JulietCSharp-mutated/runs.toml
bentoo bench --tools tool_runners/tools_csharp_juliet_mutated.toml --runs JulietCSharp-mutated/runs.toml --timeout 1200 JulietCSharp-mutated-output
./scripts/draw-benchamrk-summary-charts.py JulietCSharp-mutated-output JulietCSharp-mutated juliet_csharp_mutated
