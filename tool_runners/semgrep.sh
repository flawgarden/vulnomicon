#!/usr/bin/env bash
set -e

# Check for install/updates at https://github.com/returntocorp/semgrep

docker pull semgrep/semgrep:1.99.0 >&2

entry_point=$1
cd "$entry_point"

semgrep_version=$(docker run --rm semgrep/semgrep:1.99.0 semgrep --version)
result_filename="Semgrep-v$semgrep_version.sarif"

docker run --rm -v "${PWD}:/src" semgrep/semgrep:1.99.0 semgrep --config auto -q --sarif -o "$result_filename" . >&2
docker run --rm -v "${PWD}:/src" ubuntu sh -c "chown $(id -u "$USER"):$(id -g "$USER") -R /src" >&2

result_file="$entry_point/$result_filename"

cat "$result_file"
