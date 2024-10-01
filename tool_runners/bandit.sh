#!/usr/bin/env bash

requireCommand() {
  if ! command -v "$1" &> /dev/null
  then
    echo "$1 is required. Please install it and then try again." >&2
    exit 1
  fi
}

requireCommand python3

set -e

entry_point=$1

if [ ! -f "$HOME"/.bentoo/bandit/venv/bin/bandit ]; then
  echo "Downloading bandit..." >&2
  mkdir -p "$HOME"/.bentoo/bandit >&2
  (
    cd "$HOME"/.bentoo/bandit
    python3 -m venv venv >&2
    source venv/bin/activate >&2
    pip install bandit[sarif] >&2
  )
else
  echo "Using downloaded bandit" >&2
fi

cd "$entry_point"
result_filename="bandit.sarif"

(
  source "$HOME"/.bentoo/bandit/venv/bin/activate >&2
  bandit --format sarif --exit-zero -r . --output "$result_filename" >&2
)

cat "$result_filename"
