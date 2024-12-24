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

if [ ! -d "JulietCSharp-mutated" ]; then
  git clone https://github.com/flawgarden/JulietCSharp-mutated.git
  (cd JulietCSharp-mutated/src; rm "TestCaseSupport/TestCaseSupport.sln")
fi
(
  cd JulietCSharp-mutated;
  git fetch;
  if [[ "$UPDATE_BENCHMARKS" = "false" ]]; then
    git reset --hard 7914aaaa6ebf50bd95f587af0382ad296a1d287a
  else
    git pull
  fi
)

(cd "$BASE_DIR"/JulietCSharp-mutated; ./create_single_project.py)
(cd "$BASE_DIR"; cp -r markup/JulietCSharp-mutated/* JulietCSharp-mutated)
