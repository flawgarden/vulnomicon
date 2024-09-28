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

if [ ! -d "FlowBlot.NET" ]; then
  git clone https://github.com/flawgarden/FlowBlot.NET.git
fi
(
  cd FlowBlot.NET;
  git fetch;
  if [[ "$UPDATE_BENCHMARKS" = "false" ]]; then
    git reset --hard c2b3e2b78917527e4e29de275b62e9d6bc85da41
  else
    git pull
  fi
)

if [[ "$UPDATE_BENCHMARKS" = "true" ]]; then
  (cd "$BASE_DIR"; ./scripts/benchmarks/FlowBlot/markup.py)
fi
(cd "$BASE_DIR"; cp -r markup/FlowBlot.NET/* FlowBlot.NET)
