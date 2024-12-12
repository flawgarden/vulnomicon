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
BASE_DIR="$(cd "$SCRIPT_DIR"/../../../../ && pwd)"

EXIT_ON_ERROR="false"
BOOTSTRAP_OPTIONS=""

for OPT in "$@"; do
  if [[ "$OPT" = *"--exit-on-error"* ]]; then
      EXIT_ON_ERROR="true"
      BOOTSTRAP_OPTIONS="$BOOTSTRAP_OPTIONS --exit-on-error"
      shift 1
  fi
done

if [[ "$EXIT_ON_ERROR" = "true" ]]; then
  set -e
fi

(cd "$BASE_DIR"/reality-check; ./scripts/bootstrap.sh "go" "$BOOTSTRAP_OPTIONS")
(cd "$BASE_DIR"; cp -r reality-check/go/markup/* reality-check/go/benchmark)
