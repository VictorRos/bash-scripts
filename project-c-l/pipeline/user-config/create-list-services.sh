#!/bin/bash

set -e # Exit on any error
## Create a list of services loop from the user-config already deploy in the namespace

# Parameters
namespace=$1

COLOR_BLUE="\x1b[34m"
COLOR_YELLOW="\x1b[33m"
NO_COLOR="\x1b[0m"

info() {
  echo -e "\n${COLOR_BLUE}$1${NO_COLOR}"
}

title() {
  echo -e "\n${COLOR_YELLOW}$1${NO_COLOR}"
  echo -e "${COLOR_YELLOW}- - - - - - - - - - - - - - - - - - - - - - - - - - - - -${NO_COLOR}"
}

title "Get user-config from namespace ${namespace}\n"

user_configs=($(kubectl get secret -n "${namespace}" -o json | jq -r '.items[].metadata.name | select(. | test("user-config-*"))'))

user_config_to_create=""
for user_config in "${user_configs[@]}"; do
  service_name=${user_config#"user-config-"}

  # Retrieve user-config data to determine package label
  user_config_data=$(kubectl get secret "${user_config}" -n "${namespace}" -o json | jq -r '.data["user-config.json"]' | base64 -d)
  package_type=$(echo "${user_config_data}" | jq -r 'if (.Project == null) then "loop" else "pia" end')

  echo -e "Package: ${package_type}, app: ${service_name}"

  # Add service if package type is "loop"
  if [ "${package_type}" = "loop" ]; then
    user_config_to_create+=" ${service_name}"
  fi
done

echo "##vso[task.setvariable variable=SERVICES;isOutput=true]${user_config_to_create}"
