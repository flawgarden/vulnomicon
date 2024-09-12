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

if [ ! -d "sast-rules" ]; then
  git clone https://gitlab.com/gitlab-org/security-products/sast-rules.git
fi
(
  cd sast-rules;
  git fetch;
  if [[ "$UPDATE_BENCHMARKS" = "false" ]]; then
    git reset --hard 1a9fc57bda54c30a3d33dd8ae513f6c782d82069
  else
    git pull
  fi
)

if [[ "$UPDATE_BENCHMARKS" = "true" ]]; then
  (cd "$BASE_DIR"; ./scripts/benchmarks/sast-rules/python/markup.py "sast-rules/python")
fi
(cd "$BASE_DIR"; cp -r markup/sast-rules/* sast-rules)
