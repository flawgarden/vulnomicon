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

if [ ! -d "python-owasp-converted-mutated" ]; then
  git clone git@github.com:flawgarden/python-owasp-converted-mutated.git python-owasp-converted-mutated
fi
(
  cd python-owasp-converted-mutated;
  git fetch;
  if [[ "$UPDATE_BENCHMARKS" = "false" ]]; then
    git reset --hard 87ddc19c5f25a25836c8f08b2a30c6f0317b76c9
  else
    git pull
  fi
)

(cd "$BASE_DIR"; cp -r markup/python-owasp-converted-mutated/* python-owasp-converted-mutated)
