#!/usr/bin/env bash
set -e

docker pull bearer/bearer --platform linux/amd64 >&2

entry_point=$1
cd $entry_point

# Otherwise bearer fails to write output
chmod 777 .

docker run --platform linux/amd64 --rm -v "${PWD}:/src" bearer/bearer scan /src --format jsonv2 --output "/src/bearer.json" || true >&2

docker run --rm -v "${PWD}:/src" ubuntu sh -c "chown $(id -u $USER):$(id -g $USER) -R /src" >&2

cat bearer.json
