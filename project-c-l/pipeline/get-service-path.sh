#!/bin/bash

set -e # Exit on any error

# Example: ./get-service-path.sh <service_name> <project_name> <agent_build_directory_path>

service_name="$1"
project_name="$2"
agent_build_directory_path="$3"

project_name_lower=$(echo "${project_name}" | tr '[:upper:]' '[:lower:]')

# Handle project repository is a service (like publicRDD --> publicrdd)
if [ "${service_name}" = "${project_name_lower}" ]; then
  service_name="${project_name}"
fi
echo -e "Service name: ${service_name}\n"

# Can have multiple results (services from GI/config and arpege-web/config for example)
path_results=($(find "${agent_build_directory_path}" -maxdepth 4 -type d -name "${service_name}" -not -path "./js-compiled/*"))
path_results_str="${path_results[*]}"
echo -e "Path results: ${#path_results[@]}\n${path_results_str/ /\n}\n"

# If one result, it is service path
if [ ${#path_results[@]} -eq 1 ]; then
  service_path=${path_results[0]}
else
  # Following algo reduces results size with project name and take the one with the minimum depth
  previous_path_depth=100
  path_depth=0
  for path_result in "${path_results[@]}"; do
    # Check if path contains project name
    path=$(echo "${path_result}" | xargs -n1 | { grep "${project_name}" || true; })

    # Compute path depth
    path_depth=$(echo "${path}" | sed -e 's/\(.\)/\1\n/g' | { grep / || true; } | wc -l)

    # If path contains project name and path depth is lower than the latest matched result
    # then we update service path
    if [ "${path}" != "" ] && [ "${path_depth}" -lt ${previous_path_depth} ]; then
      previous_path_depth=${path_depth}
      service_path="${path}"
    fi
  done
fi

# Only display this echo fi Dockerfile really exists
if [ -f "${service_path}/Dockerfile" ]; then
  echo -e "Dockerfile: Dockerfile\n"
  echo "##vso[task.setvariable variable=DOCKERFILE_NAME;isOutput=true]Dockerfile"
fi

echo -e "Service path: ${service_path}\n"
echo "##vso[task.setvariable variable=SERVICE_PATH;isOutput=true]${service_path}"
