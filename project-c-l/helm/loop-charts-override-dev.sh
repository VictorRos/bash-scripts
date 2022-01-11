#!/bin/bash

set -e # Exit on any error

source "$(dirname $0)/helm-library.sh"

# It's a script that create all variables in the library "Loop-charts-override-dev"
# https://dev.azure.com/cegid/Loop/_library?itemType=VariableGroups&view=VariableGroupView&variableGroupId=492
# To run it locally you need to install this
# brew update && brew install azure-cli
# az extension add --name azure-devops
# To get the if of the group List
# az pipelines variable-group list --organization https://dev.azure.com/cegid --project Loop

# This variable is the ID of the library "Loop-charts-override-dev" on azure devops
group_list=492

# https://gist.github.com/pkuczynski/8665367
parse_yaml() {
  local prefix=$2
  local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
  sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
    -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
  awk -F$fs '{
    indent = length($1)/2;
    vname[indent] = $2;
    for (i in vname) {if (i > indent) {delete vname[i]}}
    if (length($3) > 0) {
        vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
        printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
    }
  }'
}

variables=$(az pipelines variable-group show --group-id ${group_list} --organization https://dev.azure.com/cegid --project Loop)
echo -e "Content:\n${variables}\n"

charts=($(get_charts "all"))
echo -e "Charts to update: ${#charts[@]}\n"

for chart in "${charts[@]}"; do
  echo -e "\n${chart}"

  # reset value between two directory
  config_template_resources_limits_cpu=""
  config_template_resources_limits_memory=""
  config_template_resources_requests_cpu=""
  config_template_resources_requests_memory=""

  config_resources_limits_cpu=""
  config_resources_limits_memory=""
  config_resources_requests_cpu=""
  config_resources_requests_memory=""
  # read yaml file and create env variables
  eval $(parse_yaml ${chart}/values.yaml "config_")

  name="${chart}-cpu-limits"
  exist=$(echo "${variables}" | jq ".variables[\"${name}\"]")

  if [[ $exist = null ]]; then
    if [[ "$config_resources_limits_cpu" != "" ]]; then
      echo $config_resources_limits_cpu
      value=$config_resources_limits_cpu
    elif [[ "$config_template_resources_limits_cpu" != "" ]]; then
      echo $config_template_resources_limits_cpu
      value=$config_template_resources_limits_cpu
    else
      echo -e "${COLOR_RED}Error in this repo${NO_COLOR}"
    fi

    # CPU UNITS
    if [ "${value//[!0-9]/}" -le 2 ]; then
      value="1000m"
    elif [ "${value//[!0-9]/}" -le 4 ]; then
      value="2000m"
    # MILLI CPU UNITS
    elif [ "${value//[!0-9]/}" -gt 4000 ]; then
      value="2000m"
    elif [ "${value//[!0-9]/}" -gt 2000 ]; then
      value="1000m"
    elif [ "${value//[!0-9]/}" -gt 1000 ]; then
      value="800m"
    elif [ "${value//[!0-9]/}" -gt 700 ]; then
      value="500m"
    elif [ "${value//[!0-9]/}" -gt 500 ]; then
      value="500m"
    fi

    az pipelines variable-group variable create \
      --group-id ${group_list} \
      --name ${name} \
      --value ${value} \
      --organization https://dev.azure.com/cegid \
      --project Loop
  fi

  name="${chart}-cpu-requests"
  exist=$(echo "${variables}" | jq ".variables[\"${name}\"]")

  if [[ $exist = null ]]; then
    if [[ "$config_resources_requests_cpu" != "" ]]; then
      echo $config_resources_requests_cpu
      value=$config_resources_requests_cpu
    elif [[ "$config_template_resources_requests_cpu" != "" ]]; then
      echo $config_template_resources_requests_cpu
      value=$config_template_resources_requests_cpu
    else
      echo -e "${COLOR_RED}Error in this repo${NO_COLOR}"
    fi

    # CPU UNITS
    if [ "${value//[!0-9]/}" -le 1 ]; then
      value="750m"
    elif [ "${value//[!0-9]/}" -le 4 ]; then
      value="1000m"
    # MILLI CPU UNITS
    elif [ "${value//[!0-9]/}" -gt 4000 ]; then
      value="1000m"
    elif [ "${value//[!0-9]/}" -gt 1000 ]; then
      value="750m"
    elif [ "${value//[!0-9]/}" -gt 700 ]; then
      value="500m"
    elif [ "${value//[!0-9]/}" -gt 500 ]; then
      value="250m"
    fi

    az pipelines variable-group variable create \
      --group-id ${group_list} \
      --name ${name} \
      --value ${value} \
      --organization https://dev.azure.com/cegid \
      --project Loop
  fi

  name="${chart}-memory-limits"
  exist=$(echo "${variables}" | jq ".variables[\"${name}\"]")

  if [[ $exist = null ]]; then
    if [[ "$config_resources_limits_memory" != "" ]]; then
      echo $config_resources_limits_memory
      value=$config_resources_limits_memory
    elif [[ "$config_template_resources_limits_memory" != "" ]]; then
      echo $config_template_resources_limits_memory
      value=$config_template_resources_limits_memory
    else
      echo -e "${COLOR_RED}Error in this repo${NO_COLOR}"
    fi

    # GIGA BYTES
    if [ "${value//[!0-9]/}" -le 2 ]; then
      value="1024Mi"
    elif [ "${value//[!0-9]/}" -le 5 ]; then
      value="2048Mi"
    elif [ "${value//[!0-9]/}" -le 10 ]; then
      value="4096Mi"
    # MEGA BYTES
    elif [ "${value//[!0-9]/}" -gt 10000 ]; then
      value="4096Mi"
    elif [ "${value//[!0-9]/}" -gt 5000 ]; then
      value="2048Mi"
    elif [ "${value//[!0-9]/}" -gt 2000 ]; then
      value="1024Mi"
    elif [ "${value//[!0-9]/}" -gt 1000 ]; then
      value="512Mi"
    elif [ "${value//[!0-9]/}" -gt 500 ]; then
      # Below 256Mi, NodeJS pods will crash
      value="256Mi"
    fi

    az pipelines variable-group variable create \
      --group-id ${group_list} \
      --name ${name} \
      --value ${value} \
      --organization https://dev.azure.com/cegid \
      --project Loop
  fi

  name="${chart}-memory-requests"
  exist=$(echo "${variables}" | jq ".variables[\"${name}\"]")

  if [[ $exist = null ]]; then
    if [[ "$config_resources_requests_memory" != "" ]]; then
      echo $config_resources_requests_memory
      value=$config_resources_requests_memory
    elif [[ "$config_template_resources_requests_memory" != "" ]]; then
      echo $config_template_resources_requests_memory
      value=$config_template_resources_requests_memory
    else
      echo -e "${COLOR_RED}Error in this repo${NO_COLOR}"
    fi

    # GIGA BYTES
    if [ "${value//[!0-9]/}" -le 2 ]; then
      value="512Mi"
    elif [ "${value//[!0-9]/}" -le 5 ]; then
      value="1024Mi"
    elif [ "${value//[!0-9]/}" -le 10 ]; then
      value="2048Mi"
    # MEGA BYTES
    elif [ "${value//[!0-9]/}" -gt 10000 ]; then
      value="2048Mi"
    elif [ "${value//[!0-9]/}" -gt 5000 ]; then
      value="1024Mi"
    elif [ "${value//[!0-9]/}" -gt 2000 ]; then
      value="512Mi"
    elif [ "${value//[!0-9]/}" -gt 500 ]; then
      # Below 256Mi, NodeJS pods will crash
      value="256Mi"
    fi

    az pipelines variable-group variable create \
      --group-id ${group_list} \
      --name ${name} \
      --value ${value} \
      --organization https://dev.azure.com/cegid \
      --project Loop
  fi
done
