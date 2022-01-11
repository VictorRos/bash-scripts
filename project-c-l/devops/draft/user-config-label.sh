#!/bin/bash

set -e

# Colors
blue="\033[0;34m"
green="\033[0;32m"
magenta="\033[0;35m"
# red="\033[0;31m"
yellow="\033[0;33m"
nc="\033[0m" # No Color

echo -e "${yellow}######################################################${nc}"
echo -e "${yellow}###           Update user-config labels            ###${nc}"
echo -e "${yellow}######################################################${nc}"

# Get namespaces
namespaces=($(kubectl get namespace -o=custom-columns=NAME:.metadata.name --no-headers))
echo -e "\n${#namespaces[@]} namespaces found"

for namespace in "${namespaces[@]}"; do
  echo -e "\n${blue}Namespace ${namespace}${nc}"

  # Get user-config for the current namespace
  user_configs=($(kubectl get secret -n "${namespace}" -o json | jq -r '.items[].metadata.name | select(. | test("user-config-*"))'))
  echo -e "\n${green}${#user_configs[@]} user-config found${nc}"

  for i in "${!user_configs[@]}"; do
    # To beautify logs
    prefixLog=""
    if [ "$i" -eq 0 ]; then
      prefixLog="\n"
    fi
    user_config="${user_configs[$i]}"
    service_name=${user_config#"user-config-"}

    # Retrieve user-config data to determine package label
    user_config_data=$(kubectl get secret "${user_config}" -n "${namespace}" -o json | jq -r '.data["user-config.json"]' | base64 -d)
    package_type=$(echo "${user_config_data}" | jq -r 'if (.Project == null) then "loop" else "pia" end')

    echo -e "${prefixLog}${magenta}Labels - type: user-config, package: ${package_type}, app: ${service_name}${nc}"

    # Patch user-config
    kubectl patch secret -n "${namespace}" "${user_config}" --patch '{"metadata":{"labels":{"app":"'"${service_name}"'","package":"'"${package_type}"'","type":"user-config"}}}'
  done
done
