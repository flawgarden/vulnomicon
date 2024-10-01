#!/usr/bin/env bash
set -e

entry_point=$1
cd $entry_point

result_filename="codeql.sarif"
export language="java"

docker pull ocelaiwo/codeql-java:2.16.5 >&2

docker run --rm -v $(pwd):/benchmark ocelaiwo/codeql-java:2.16.5 sh -c "cd benchmark; /codeql-bundle-linux64/codeql/codeql database create codeql_db --language=${language}" >&2

# upgrade the db if necessary
docker run --rm -v $(pwd):/benchmark ocelaiwo/codeql-java:2.16.5 sh -c "cd benchmark; /codeql-bundle-linux64/codeql/codeql database upgrade codeql_db" >&2

docker run --rm -v $(pwd):/benchmark ocelaiwo/codeql-java:2.16.5 sh -c "cd benchmark; /codeql-bundle-linux64/codeql/codeql database analyze codeql_db ${language}-security-and-quality.qls --format=sarif-latest --output=$result_filename" >&2

docker run --rm -v $(pwd):/benchmark ubuntu sh -c "chown $(id -u $USER):$(id -g $USER) -R /benchmark" >&2

result_file="$entry_point/$result_filename"

cat $result_file
