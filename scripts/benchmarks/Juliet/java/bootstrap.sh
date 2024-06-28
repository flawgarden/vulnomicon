#!/bin/bash

requireCommand() {
  if ! command -v "$1" &> /dev/null
  then
    echo "$1 is required. Please install it and then try again."
    exit 1
  fi
}

requireCommand docker
requireCommand python3
requireCommand unzip
requireCommand mvn
requireCommand javac

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

if [ ! -d "JulietJava" ]; then
  echo "Downloading JulietJava..."
  curl -o JulietJava.zip "https://samate.nist.gov/SARD/downloads/test-suites/2017-10-01-juliet-test-suite-for-java-v1-3.zip"
  if [[ "$UPDATE_BENCHMARKS" = "false" ]]; then
    EXPECTED_SHA256SUM="d985f4177c2bcd7b03455a05c1c8f2e755f55c9eb250accd052f05f877347e60"
    if ! echo "${EXPECTED_SHA256SUM}  JulietJava.zip" | sha256sum --check --status; then
      echo "sha256 failed for the Juliet download!"
      rm JulietCSharp.zip
      exit 2
    fi
  fi
  unzip JulietJava.zip -d "."
  mv "Java" "JulietJava"
  rm JulietJava.zip
fi

# the order is important so main Juliet sln will not be counted as a CWE
(cd "$BASE_DIR"; ./scripts/benchmarks/Juliet/java/markup.py)
