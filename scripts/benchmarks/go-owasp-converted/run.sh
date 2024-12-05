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

bentoo template --tools tool_runners/tools_go.toml go-owasp-converted > go-owasp-converted/runs.toml
bentoo bench --tools tool_runners/tools_go.toml --runs go-owasp-converted/runs.toml --timeout 1200 go-owasp-converted-output
./scripts/draw-benchamrk-summary-charts.py go-owasp-converted-output go-owasp-converted go_owasp_converted
