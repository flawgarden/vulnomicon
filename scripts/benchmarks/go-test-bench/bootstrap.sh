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
requireCommand go
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

if [ ! -d "go-test-bench" ]; then
  git clone https://github.com/Contrast-Security-OSS/go-test-bench.git
fi
(
  cd go-test-bench;
  git fetch;
  if [[ "$UPDATE_BENCHMARKS" = "false" ]]; then
    git reset --hard 37abd5005ce87db30747adb51b0d43736b60f373
  else
    git pull
  fi
)

(cd "$BASE_DIR"/go-test-bench; go build ./...)
(cd "$BASE_DIR"; cp -r markup/go-test-bench/* go-test-bench)
