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
requireCommand xbuild

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BASE_DIR="$(cd $SCRIPT_DIR/../ && pwd)"

EXIT_ON_ERROR="false"
UPDATE_BENCHMARKS="false"

for OPT in $@; do
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

cd $BASE_DIR

if [ ! -d "JulietCSharp" ]; then
  echo "Downloading JulietCSharp..."
  curl -o JulietCSharp.zip "https://samate.nist.gov/SARD/downloads/test-suites/2020-08-01-juliet-test-suite-for-csharp-v1-3.zip"
  julietsha = $(sha256sum juliet.zip)
  if [ $julietsha -ne "2e6dbac4741fb020a0b1c2db69e98aed165987df2bd70bd51f7c8c5302c8e8f8" ]; then
    echo "sha256 failed for the Juliet download!"
    rm JulietCSharp.zip
    exit 2
  fi
  unzip JulietCSharp.zip -d "JulietCSharp"
  rm JulietCSharp.zip
# fixing case-sensitive directory name
  (cd JulietCSharp/src; mv "testcasesupport" "TestCaseSupport")
# deleting previously needed temporary fix, see https://github.com/dotnet/runtime/issues/17471
# as Mono improved since Juliet was made, it is no longer necessary
  (cd JulietCSharp/lib; rm "System.Runtime.InteropServices.RuntimeInformation.dll")
fi

# the order is important so main Juliet sln will not be counted as a CWE
(cd $BASE_DIR; ./scripts/markup_juliet.py)
(cd $BASE_DIR/JulietCSharp; ../scripts/create_single_juliet_project.py)

# specifying mono-xbuild as the compiling tool of the project
(cd $BASE_DIR/JulietCSharp; cp ../scripts/buildForJuliet.sh build.sh)
