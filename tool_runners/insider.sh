#!/usr/bin/env bash
set -e

# Check for install/updates at https://github.com/insidersec/insider

insider_version=3.0.0 # We use docker tag 3.0.0, for some reason insider's -version option does something weird

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --tech)
      TECH="$2"
      shift # past argument
      shift # past value
      ;;
    --*|-*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

if ! { [ "$TECH" = "java" ] || [ "$TECH" = "csharp" ]; } then
    echo "TECH can only be java or csharp (was $TECH)" >&2
    exit 1
fi

entry_point=$1
cd "$entry_point"

result_filename="insider-v$insider_version.json"

docker run --entrypoint /bin/sh --rm -v "$entry_point":/target-project insidersec/insider:3.0.0 -c "./insider -tech $TECH -no-html -target /target-project; cp report.json /target-project/$result_filename" >&2

docker run --rm -v "${PWD}:/src" ubuntu sh -c "chown $(id -u "$USER"):$(id -g "$USER") -R /src" >&2

result_file="$entry_point/$result_filename"

cat "$result_file"
