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
BASE_DIR="$(cd $SCRIPT_DIR && pwd)"

cd $BASE_DIR

SCRIPT_JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64/"
export JAVA_HOME="${SCRIPT_JAVA_HOME}"

if [ ! -d "BenchmarkJava" ]; then
  git clone https://github.com/OWASP-Benchmark/BenchmarkJava.git
fi
(cd BenchmarkJava; git fetch; git reset --hard d6a3e016b9239c486f3fe1bf2af2bf3e7b01fa56)

if [ ! -d "BenchmarkJava-mutated" ]; then
  git clone https://github.com/flawgarden/BenchmarkJava-mutated.git
fi
(cd BenchmarkJava-mutated; git fetch; git reset --hard ac71f3701a4775819935aac4243939f11aac54e7)

if [ ! -d "reality-check" ]; then
  git clone https://github.com/flawgarden/reality-check.git
fi
(cd reality-check; git fetch; git reset --hard 1feceb93f505ade1ebed3ecf0f4bb3db514f6670)


(cd $BASE_DIR/BenchmarkJava; mvn compile)
(cd $BASE_DIR/BenchmarkJava-mutated; mvn compile)
(cd $BASE_DIR; ./scripts/markup_benchmark_java_all.py)
(cd $BASE_DIR/reality-check; ./scripts/bootstrap.sh)
(cd $BASE_DIR; ./scripts/bentoo.sh)