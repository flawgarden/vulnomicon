#!/usr/bin/env bash

requireCommand() {
  if ! command -v "$1" &> /dev/null
  then
    echo "$1 is required. Please install it and then try again." >&2
    exit 1
  fi
}

requireCommand go

set -e

entry_point=$1

go install github.com/securego/gosec/v2/cmd/gosec@latest >&2
gosec="$(go env GOPATH)/bin/gosec";


cd "$entry_point"
result_filename="gosec.sarif"

(
  eval "$gosec -no-fail -fmt sarif -out $result_filename ./... " >&2
)

cat "$result_filename"
