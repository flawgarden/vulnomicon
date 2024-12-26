#!/bin/bash

requireCommand() {
  if ! command -v "$1" &> /dev/null
  then
    echo "$1 is required. Please install it and then try again."
    exit 1
  fi
}

requireCommand git
requireCommand docker
requireCommand javac
requireCommand mvn
requireCommand python3

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BASE_DIR="$(cd "$SCRIPT_DIR"/../../../ && pwd)"

EXIT_ON_ERROR="false"
UPDATE_BENCHMARKS="false"

for OPT in "$@"; do
  if [[ "$OPT" = *"--exit-on-error"* ]]; then
      EXIT_ON_ERROR="true"
      shift 1
  fi
  if [[ "$OPT" = *"--update"* ]]; then
      UPDATE_BENCHMARKS="true"
      shift 1
  fi
done

if [[ "$EXIT_ON_ERROR" = "true" ]]; then
  set -e
fi

cd "$BASE_DIR"

if [[ ! -v VULNOMICON_JAVA_HOME_22 ]]; then
    echo "VULNOMICON_JAVA_HOME_22 is not set"
    exit 1
elif [[ -z "${VULNOMICON_JAVA_HOME_22}" ]]; then
    echo "VULNOMICON_JAVA_HOME_22 is set to the empty string" exit 1
else
    echo "VULNOMICON_JAVA_HOME_22 has the value: ${VULNOMICON_JAVA_HOME_22}"
fi

export JAVA_HOME="${VULNOMICON_JAVA_HOME_22}"

if [ ! -d "BenchmarkJava-mutated" ]; then
  git clone https://github.com/flawgarden/BenchmarkJava-mutated.git
fi
(
  cd BenchmarkJava-mutated;
  git fetch;
  if [[ "$UPDATE_BENCHMARKS" = "false" ]]; then
    git reset --hard 2cb7ba95bbf21c30d5501729c190bd95c555056b
  else
    git pull
  fi
)

(cd "$BASE_DIR"/BenchmarkJava-mutated; mvn compile)
