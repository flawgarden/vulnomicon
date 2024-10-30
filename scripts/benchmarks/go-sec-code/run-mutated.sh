#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BASE_DIR="$(cd "$SCRIPT_DIR"/../../../ && pwd)"

cd "$BASE_DIR" || exit;

if [ ! -f "bentoo" ]; then
    echo "Please run bentoo.sh beforehand"
fi

if [ ! -d "tool_runners" ]; then
    echo "Please run bentoo.sh beforehand"
fi

PATH=$PATH:$(pwd)

bentoo template --tools tool_runners/tools_go.toml go-sec-code-mutated > go-sec-code-mutated/runs.toml
bentoo bench --tools tool_runners/tools_go.toml --runs go-sec-code-mutated/runs.toml --timeout 1200 go-sec-code-mutated-output
./scripts/draw-benchamrk-summary-charts.py go-sec-code-mutated-output go-sec-code-mutated go_sec_code_mutated
