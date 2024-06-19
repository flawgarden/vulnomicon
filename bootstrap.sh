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
requireCommand python3

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BASE_DIR="$(cd "$SCRIPT_DIR" && pwd)"

EXIT_ON_ERROR="false"
BOOTSTRAP_OPTIONS=""

for OPT in "$@"; do
  if [[ "$OPT" = *"--exit-on-error"* ]]; then
      EXIT_ON_ERROR="true"
      BOOTSTRAP_OPTIONS="$BOOTSTRAP_OPTIONS --exit-on-error"
      shift 1
  fi
  if [[ "$OPT" = *"--update"* ]]; then
      BOOTSTRAP_OPTIONS="$BOOTSTRAP_OPTIONS --update"
      shift 1
  fi
done

if [[ "$EXIT_ON_ERROR" = "true" ]]; then
  set -e
fi

cd "$BASE_DIR"

(cd "$BASE_DIR"; ./scripts/python-version-checker.py)

(cd "$BASE_DIR"; ./scripts/bootstrap-BenchmarkJava.sh "$BOOTSTRAP_OPTIONS")
(cd "$BASE_DIR"; ./scripts/bootstrap-BenchmarkJava-mutated.sh "$BOOTSTRAP_OPTIONS")
(cd "$BASE_DIR"; ./scripts/bootstrap-reality-check.sh "$BOOTSTRAP_OPTIONS")
(cd "$BASE_DIR"; ./scripts/bootstrap-JulietCSharp.sh "$BOOTSTRAP_OPTIONS")
(cd "$BASE_DIR"; ./scripts/bootstrap-sast-rules.sh "$BOOTSTRAP_OPTIONS")

(cd "$BASE_DIR"; ./scripts/bentoo.sh)
