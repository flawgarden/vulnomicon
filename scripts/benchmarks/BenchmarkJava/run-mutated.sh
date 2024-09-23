#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BASE_DIR="$(cd "$SCRIPT_DIR"/../../../ && pwd)"

cd "$BASE_DIR" || exit;

if [[ ! -v VULNOMICON_JAVA_HOME_22 ]]; then
    echo "VULNOMICON_JAVA_HOME_22 is not set"
    exit 1
elif [[ -z "${VULNOMICON_JAVA_HOME_22}" ]]; then
    echo "VULNOMICON_JAVA_HOME_22 is set to the empty string"
    exit 1
else
    echo "VULNOMICON_JAVA_HOME_22 has the value: ${VULNOMICON_JAVA_HOME_22}"
fi

export JAVA_HOME="${VULNOMICON_JAVA_HOME_22}"

if [ ! -f "bentoo" ]; then
    echo "Please run bentoo.sh beforehand"
fi

if [ ! -d "tool_runners" ]; then
    echo "Please run bentoo.sh beforehand"
fi

PATH=$PATH:$(pwd)

bentoo template --tools tool_runners/tools_java.toml BenchmarkJava-mutated > BenchmarkJava-mutated/runs.toml
bentoo bench --tools tool_runners/tools_java.toml --runs BenchmarkJava-mutated/runs.toml --timeout 1200 BenchmarkJava-mutated-output
./scripts/draw-benchamrk-summary-charts.py BenchmarkJava-mutated-output BenchmarkJava-mutated benchmark_java_mutated
