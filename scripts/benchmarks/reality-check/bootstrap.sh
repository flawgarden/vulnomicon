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
BOOTSTRAP_OPTIONS=""

for OPT in "$@"; do
  if [[ "$OPT" = *"--exit-on-error"* ]]; then
      EXIT_ON_ERROR="true"
      BOOTSTRAP_OPTIONS="$BOOTSTRAP_OPTIONS --exit-on-error"
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

if [ ! -d "reality-check" ]; then
  git clone https://github.com/flawgarden/reality-check.git
fi
(
  cd reality-check;
  git fetch;
  if [[ "$UPDATE_BENCHMARKS" = "false" ]]; then
    git reset --hard 95f33492a20b1fe29005998a4f27f5db2c794c90
  else
    git pull
  fi
)

(cd "$BASE_DIR"; ./scripts/benchmarks/reality-check/java/bootstrap.sh "$BOOTSTRAP_OPTIONS")
(cd "$BASE_DIR"; ./scripts/benchmarks/reality-check/csharp/bootstrap.sh "$BOOTSTRAP_OPTIONS")
(cd "$BASE_DIR"; ./scripts/benchmarks/reality-check/python/bootstrap.sh "$BOOTSTRAP_OPTIONS")
(cd "$BASE_DIR"; ./scripts/benchmarks/reality-check/go/bootstrap.sh "$BOOTSTRAP_OPTIONS")
