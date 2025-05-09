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
      BOOTSTRAP_OPTIONS="$BOOTSTRAP_OPTIONS --update"
      shift 1
  fi
done

if [[ "$EXIT_ON_ERROR" = "true" ]]; then
  set -e
fi

cd "$BASE_DIR"

if [ ! -d "python-owasp-converted" ]; then
  git clone https://github.com/flawgarden/python-owasp-converted-mutated.git python-owasp-converted
fi
(
  cd python-owasp-converted;
  git fetch;
  if [[ "$UPDATE_BENCHMARKS" = "false" ]]; then
    git reset --hard 0b0e22c5e5c746e7d573243ac460882b6f1cd5b7
  else
    git pull
  fi
)
