#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BASE_DIR="$(cd "$SCRIPT_DIR"/../../../ && pwd)"

cd "$BASE_DIR" || exit;

if [[ ! -v VULNOMICON_JAVA_HOME_11 ]]; then
    echo "VULNOMICON_JAVA_HOME_11 is not set"
    exit 1
elif [[ -z "${VULNOMICON_JAVA_HOME_11}" ]]; then
    echo "VULNOMICON_JAVA_HOME_11 is set to the empty string"
    exit 1
else
    echo "VULNOMICON_JAVA_HOME_11 has the value: ${VULNOMICON_JAVA_HOME_11}"
fi

export JAVA_HOME="${VULNOMICON_JAVA_HOME_11}"

if [ ! -f "bentoo" ]; then
    echo "Please run bentoo.sh beforehand"
fi

if [ ! -d "tool_runners" ]; then
    echo "Please run bentoo.sh beforehand"
fi

PATH=$PATH:$(pwd)

bentoo template --tools tool_runners/tools_java.toml BenchmarkJava > BenchmarkJava/runs.toml
bentoo bench --tools tool_runners/tools_java.toml --runs BenchmarkJava/runs.toml --timeout 1200 BenchmarkJava-output
./scripts/draw-benchamrk-summary-charts.py BenchmarkJava-output BenchmarkJava benchmark_java
