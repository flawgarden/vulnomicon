#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BASE_DIR="$(cd "$SCRIPT_DIR"/../../../ && pwd)"

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

bentoo template --tools tool_runners/tools_python.toml python-owasp-converted > python-owasp-converted/runs.toml
bentoo bench --tools tool_runners/tools_python.toml --runs python-owasp-converted/runs.toml python-owasp-converted-output
./scripts/draw-benchamrk-summary-charts.py python-owasp-converted-output python-owasp-converted python_owasp_converted
