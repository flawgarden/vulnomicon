#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BASE_DIR="$(cd "$SCRIPT_DIR"/../../../../ && pwd)"

cd "$BASE_DIR" || exit;

if [[ ! -v VULNOMICON_JAVA_HOME_8 ]]; then
    echo "VULNOMICON_JAVA_HOME_8 is not set"
    exit 1
elif [[ -z "${VULNOMICON_JAVA_HOME_8}" ]]; then
    echo "VULNOMICON_JAVA_HOME_8 is set to the empty string"
    exit 1
else
    echo "VULNOMICON_JAVA_HOME_8 has the value: ${VULNOMICON_JAVA_HOME_8}"
fi

export JAVA_HOME="${VULNOMICON_JAVA_HOME_8}"

echo "Warning: reality-check is a big benchmark"
echo "Running all available tools on it can take a vast amount of time"
echo -n "Proceed (yes/no)? "
read -r proceed

if [ ! "$proceed" = "yes" ]; then
    echo "Exiting"
    exit 0
fi

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

bentoo template --tools tool_runners/tools_java.toml reality-check/java/benchmark > reality-check/java/benchmark/runs.toml
bentoo bench --tools tool_runners/tools_java.toml --runs reality-check/java/benchmark/runs.toml --timeout 3600 reality-check-java-output
./scripts/draw-benchamrk-summary-charts.py reality-check-java-output reality-check-java reality_check_java

