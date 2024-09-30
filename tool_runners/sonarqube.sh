#!/usr/bin/env bash

# this script will
# - create a sonarqube server using the default configuration
# - setup basic things (account, project, token)
# - start a scan (takes >= 1 hour on mac)
# - create a report file
# - shutdown sonarqube server

requireCommand() {
  if ! command -v "$1" &> /dev/null
  then
    echo "$1 is required. Please install it and then try again." >> /dev/stderr
    exit 1
  fi
}

requireCommand curl
requireCommand docker
requireCommand jq

entry_point=$1
cd $entry_point
echo "$entry_point" >> /dev/stderr

# Check for install/updates at https://github.com/SonarSource/sonarqube
# This is Page size, If facing JQ Errors due to Long Arguments, Decrease this Number. Tested with SonarQube 9.9 LTS, 50 and 100 where producing lots of errors,
elements_per_request=20

sonar_port="9876"
sonar_host="http://localhost:$sonar_port"
sonar_project="benchmark"
sonar_user="admin"
sonar_default_password="admin"
sonar_password="password"

for id in $(docker ps -q)
do
    if [[ $(docker port "${id}") == *"${sonar_port}"* ]]; then
        echo "stopping container ${id}" >> /dev/stderr
        docker stop "${id}" > /dev/null
    fi
done

if [ -f pom.xml ]; then
  echo "Compile with mvn" >> /dev/stderr
    mvn clean package -f pom.xml -B -V -e \
      -Dfindbugs.skip -Dcheckstyle.skip -Dpmd.skip=true -Dspotbugs.skip \
      -Denforcer.skip -Dmaven.javadoc.skip -DskipTests -Dmaven.test.skip.exec \
      -Dlicense.skip=true -Drat.skip=true -Dspotless.check.skip=true > /dev/null
elif [ -f build.gradle ]; then
  echo "Compile with gradle" >> /dev/stderr
  gradle build > /dev/null
elif [ -f build.xml ]; then
  echo "Compile with ant" >> /dev/stderr
  ant compile > /dev/null
fi

echo "Creating temporary SonarQube instance" >> /dev/stderr

docker pull sonarqube:10.4.1-community > /dev/null
docker pull sonarsource/sonar-scanner-cli > /dev/null

# start local sonarqube
container_id=$(docker run --rm -d -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true -p "$sonar_port:9000" sonarqube:10.4.1-community) > /dev/null

echo "Waiting for instance to come up" >> /dev/stderr

# wait for container to come up
while [[ "$(curl --connect-timeout 5 --max-time 5 --retry 60 --retry-delay 0 --retry-max-time 120 -s -o /dev/null -w '%{http_code}' "$sonar_host")" != "200" ]]; do
  sleep 3;
done

# wait for sonarqube to be started
while [[ "$(curl --silent "$sonar_host/api/system/status" | jq -r '.status')" != "UP" ]]; do
  sleep 3;
done

echo "Setting up instance" >> /dev/stderr

# change default password
curl "$sonar_host/api/users/change_password" --silent -u "$sonar_user:$sonar_default_password" -X POST --data-raw "login=$sonar_user&password=$sonar_password&previousPassword=$sonar_default_password" -o /dev/null

# create project
curl "$sonar_host/api/projects/create" --silent -u "$sonar_user:$sonar_password" -X POST --data-raw "project=$sonar_project&name=$sonar_project" -o /dev/null

# create token
sonar_token=$(curl "$sonar_host/api/user_tokens/generate" --silent -u "$sonar_user:$sonar_password" -X POST --data-raw "name=$(date)" | jq -r '.token')

echo "Starting scan (might take some time!)" >> /dev/stderr

# run scan (using net=host to be able to connect to localhost sonarqube)
docker run --env SONAR_SCANNER_OPTS=-Xmx4g --net=host --rm -v ~/.m2:/root/.m2 -v "$(pwd)":"/benchmark" -w "/benchmark" sonarsource/sonar-scanner-cli \
  -Dsonar.java.binaries="." -Dsonar.scm.disabled="true" -Dsonar.projectKey="$sonar_project" -Dsonar.host.url="$sonar_host" -Dsonar.login="$sonar_token" \
  -Dsonar.sources="." > /dev/null

echo "Waiting for SonarQube CE to finish task" >> /dev/stderr

while [[ "$(curl --silent -u "$sonar_token:" "$sonar_host/api/ce/component?component=$sonar_project" | jq -r '.current.status')" != "SUCCESS" ]]; do
  sleep 3;
done

echo "Generating report..." >> /dev/stderr

sonarqube_version=$(curl --silent -u "$sonar_token:" "$sonar_host/api/server/version")
result_filename="sonarqube-v$sonarqube_version.json"

# SonarQube does not provide a download option so we've to create the result file manually :(

result='{"issues":[], "hotspots": []}'
rules='[]'


## WE ARE GOING TO DISCARD RULE CHERRY PICKING. SO ALL RESULTS ARE REPORTED REGARDLESS SO THAT BENCHMARK CAN POPULATE RESULTS & SCORE ACCORDINGLY.
## The content/data structure returned is controled by SONARQUEBE end server, Benchmark Script picks them accordingly and match them back to test cases and create the score. 
## If returned data are not structured in a way expected by Benchmark/Score calculator. Example: CWE/DataPoint missed then results will not be counted/scored. This can end up in in-correct/Lower Score calculation. 
## rules_count=$(curl --silent -u "$sonar_token:" "$sonar_host/api/rules/search?p=1&ps=1" | jq -r '.total')
##page=1
##echo "rule count is: $rules_count"

## while (((page - 1) * elements_per_request < rules_count)); do
##  rules=$(echo "$rules" | jq ". += $(curl --silent -u "$sonar_token:" "$sonar_host/api/rules/search?p=$page&ps=$elements_per_request" | jq '.rules | map( .key ) | map( select(. | contains("java:") ) )')")
##  page=$((page+1))
##  echo "rule page: $page"
##  sleep 1;
## done
## rules=$(echo "$rules" | jq '. | join(",")' | sed 's/java:S1989,//')

issues_count=$(curl --silent -u "$sonar_token:" "$sonar_host/api/issues/search?p=1&ps=1&types=VULNERABILITY&componentKeys=$sonar_project" | jq -r '.paging.total')
page=1

echo "Vulnerability Issue count is: $issues_count" >> /dev/stderr

## We are using two files to write results to. One as buffer the other as final to incrementally add results and swap in-between.
## This helps to have some sort of fault tolerance. If jq hits long argument or sonarqube sends back impaired data/empty for a single page, previous progress of result collection will not be erased/lost retroactively.
echo '{"issues":[], "hotspots": []}' > buffdump.json;
echo '{"issues":[], "hotspots": []}' > resdump.json;

while (((page - 1) * elements_per_request < issues_count)); do
 cat resdump.json > buffdump.json;
 itemcount=$(($page * $elements_per_request))
 echo "processing Vulnerablity issues, page: $page up to $itemcount items out of total $issues_count" >> /dev/stderr
 issues_page=$(curl --silent -u "$sonar_token:" "$sonar_host/api/issues/search?types=VULNERABILITY&p=$page&ps=$elements_per_request&componentKeys=$sonar_project" | jq '.issues')
 if [ "$issues_page" ]; then
   cat buffdump.json | jq ".issues += ${issues_page}" > resdump.json;
 else
   echo "Empty. Error reading Vulnerability issues at Page:$page !" >> /dev/stderr
 fi
 page=$((page+1))
done

hotspot_count=$(curl --silent -u "$sonar_token:" "$sonar_host/api/hotspots/search?projectKey=$sonar_project&p=1&ps=1" | jq -r '.paging.total')
page=1
echo "Hotspot Count is: $hotspot_count" >> /dev/stderr

cat resdump.json > buffdump.json
while (((page - 1) * elements_per_request < hotspot_count)); do
  cat resdump.json > buffdump.json
  itemcount=$(($page * $elements_per_request))
  echo "processing Hotspots, page: $page up to $itemcount items out of total $hotspot_count" >> /dev/stderr
  hotspot_page=$(curl --silent -u "$sonar_token:" "$sonar_host/api/hotspots/search?projectKey=$sonar_project&p=$page&ps=$elements_per_request" | jq '.hotspots')
  if [ "$hotspot_page" ]; then
    cat buffdump.json | jq ".hotspots += ${hotspot_page}" > resdump.json;
  else
    echo "Empty. Error reading Hotspot at Page:$page !" >> /dev/stderr
  fi
  page=$((page+1))
done
echo "Writing end results json content" >> /dev/stderr
cp resdump.json "${result_filename}";
echo "Done, please go ahead an generate the scorecard" >> /dev/stderr
## cleanup the two files generated to record results, if want them for debug, you can comment the following line
rm resdump.json buffdump.json;

echo "Shutting down SonarQube" >> /dev/stderr

docker stop "$container_id" > /dev/null

docker run --rm -v "${PWD}:/src" ubuntu sh -c "chown $(id -u $USER):$(id -g $USER) -R /src" > /dev/null

result_file="$entry_point/$result_filename"

cat $result_file
