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
requireCommand pkg-config

requireLibrary() {
  if ! pkg-config --exists "$1" &> /dev/null
  then
    echo "$1 is required. Please install it and then try again."
    exit 1
  fi
}

requireLibrary libxml-2.0

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

if [ ! -d "go-sec-code-mutated" ]; then
  git clone https://github.com/flawgarden/go-sec-code-mutated.git
fi
(
  cd go-sec-code-mutated;
  git fetch;
  if [[ "$UPDATE_BENCHMARKS" = "false" ]]; then
    git reset --hard 45fa4739a8a7d58af835e827b4eb2574a728544b
  else
    git pull
  fi
)

(cd "$BASE_DIR"/go-sec-code-mutated; go mod edit -require=github.com/lestrrat-go/libxml2@v0.0.0-20240905100032-c934e3fcb9d3; go mod tidy; go build ./...)
