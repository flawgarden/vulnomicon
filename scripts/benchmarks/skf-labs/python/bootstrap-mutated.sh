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
BASE_DIR="$(cd "$SCRIPT_DIR"/../../../../ && pwd)"

if [ ! -d "$BASE_DIR/skf-labs-mutated" ]; then
  echo "Run scripts/benchmarks/skf-labs/bootstrap-mutated.sh beforehand"
  exit 1
fi

EXIT_ON_ERROR="false"

for OPT in "$@"; do
  if [[ "$OPT" = *"--exit-on-error"* ]]; then
      EXIT_ON_ERROR="true"
      shift 1
  fi
done

if [[ "$EXIT_ON_ERROR" = "true" ]]; then
  set -e
fi

cd "$BASE_DIR"

(cd "$BASE_DIR"; cp -r markup/skf-labs-mutated/python-mutated/* skf-labs-mutated/python-mutated)
