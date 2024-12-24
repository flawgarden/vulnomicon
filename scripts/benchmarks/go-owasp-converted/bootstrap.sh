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

if [ ! -d "go-owasp-converted" ]; then
  git clone https://github.com/flawgarden/go-owasp-converted-mutated.git go-owasp-converted
fi
(
  cd go-owasp-converted;
  git fetch;
  if [[ "$UPDATE_BENCHMARKS" = "false" ]]; then
    git reset --hard 985fb705e36ea97f2d7bd37ebd31d44b251a7584
  else
    git pull
  fi
)

(cd "$BASE_DIR"/go-owasp-converted; go mod edit -require=github.com/lestrrat-go/libxml2@v0.0.0-20240905100032-c934e3fcb9d3; go mod tidy; go build ./...)
