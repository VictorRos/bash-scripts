#!/bin/bash

set -e

############################################################################################
#######################          Update sonar configuration token           ################
#######################    Update the token azure devops on sonar for PR    ################
############################################################################################
# TOKEN="##############"
# SVCPRODLOOP_TOKEN="##############"

curl_call() {
  local project=$1
  local data_raw=$2

  result=$(curl -s -S 'https://sonarcloud.io/api/settings/set' \
    -H 'Connection: keep-alive' \
    -H 'sec-ch-ua: "Chromium";v="92", " Not A;Brand";v="99", "Google Chrome";v="92"' \
    -H 'Accept: application/json' \
    -H 'DNT: 1' \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.107 Safari/537.36' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'Origin: https://sonarcloud.io' \
    -H 'Sec-Fetch-Site: same-origin' \
    -H 'Sec-Fetch-Mode: cors' \
    -H 'Sec-Fetch-Dest: empty' \
    -H "Referer: https://sonarcloud.io/project/settings?category=pull_request&id=${project}" \
    -H 'Accept-Language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7' \
    -H "Authorization: Basic $TOKEN64" \
    -H 'sec-gpc: 1' \
    --data-raw "${data_raw}" \
    --compressed)
  echo "$result"
}

TOKEN64=$(echo -n "$TOKEN:" | base64)

searched=("loop" "pia" "yupana")
projects=()

for search in "${searched[@]}"; do
  projectsGet=($(curl -s -S "https://sonarcloud.io/api/components/search_projects?boostNewProjects=true&ps=200&facets=reliability_rating%2Csecurity_rating%2Csqale_rating%2Ccoverage%2Cduplicated_lines_density%2Cncloc%2Calert_status%2Clanguages%2Ctags&f=analysisDate%2CleakPeriodDate&organization=cegidgroup&filter=query%20%3D%20%22${search}%22" \
    -H 'Accept: application/json' \
    -H 'Accept-Language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7' \
    -H "Authorization: Basic ${TOKEN64}" \
    -H "Referer: https://sonarcloud.io/organizations/cegidgroup/projects?search=${search}" \
    --compressed | jq -r '.components[].key'))
  projects+=("${projectsGet[@]}")
done

projectsUniq=($(echo "${projects[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
echo -e "\n##### Projects Found #####"
echo "${projectsUniq[@]}"

error=0
for project in "${projectsUniq[@]}"; do
  echo -e "\n##### Update Sonar PAT token for project \"${project}\" #####"
  # Set provider to "Azure DevOps Services"
  curlResponse=$(curl_call "${project}" "key=sonar.pullrequest.provider&component=${project}&value=Azure%20DevOps%20Services")
  if [[ "$curlResponse" =~ "error" ]]; then
    echo "Error: ${curlResponse}"
    error=1
  fi

  # Set secured token to SvcProdLoop token
  curlResponse=$(curl_call "${project}" "key=sonar.pullrequest.vsts.token.secured&component=${project}&value=${SVCPRODLOOP_TOKEN}")
  if [[ "$curlResponse" =~ "error" ]]; then
    echo "Error: ${curlResponse}"
    error=1
  fi
done

exit $error
