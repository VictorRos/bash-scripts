#!/bin/bash

# Update all Kubernetes credentials for each subscriptions
# Prerequisites: You must install azure-cli and jq

set -e

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

source "${SCRIPT_DIR}/library/nv_library.sh"

# Trigger az login if not connected
is_connect_with_az_cli

# Subscriptions
subscriptions=(
  "App-Yupana" # Old DEV subscription
  "SAAS-8307-DEV"
  "SAAS-8307-INTE"
  "SAAS-8307-PROD"
)

for subscription in "${subscriptions[@]}"; do
  echo -e "\n${PINK}***** Subscription ${subscription} *****${NO_COLOR}"

  # Ignore the subscription if it is not known by the user
  if [ "$(is_subscription_known_by_user "${subscription}")" = "1" ]; then
    echo -e "\n${RED}You do not have acces to this subscription.${NO_COLOR}"
    continue
  fi

  # Connect to the subscription
  az account set -s "${subscription}"

  # Clusters defined in the selected subscription
  clusters=()
  while IFS='' read -r line; do clusters+=("${line}"); done < <(az aks list | jq -r '.[].name')
  # Stop here if there is not cluster for this subscription
  if [ ${#clusters[@]} -eq 0 ]; then
    echo -e "\n${DODGER_BLUE}No cluster found${NO_COLOR}"
    continue
  fi

  for cluster in "${clusters[@]}"; do
    # Accept only cluster with "CON830700AKS*" pattern
    if [[ ${cluster} == CON830700AKS* ]]; then
      echo -e "\n${DODGER_BLUE}Cluster: ${cluster}${NO_COLOR}"
      resourceGroup=$(az aks list | jq -r ".[] | select(.name == \"${cluster}\") | .resourceGroup")
      echo -e "${DODGER_BLUE}Resource Group: ${resourceGroup}${NO_COLOR}"

      # Disable exit on error only for next command
      set +e
      outputCreds=$(az aks get-credentials -g "${resourceGroup}" -n "${cluster}" --overwrite-existing 2>&1)
      resultCreds=$?
      set -e

      # Write in LIME if OK, in RED if it is not
      if [ ${resultCreds} -eq 0 ]; then
        echo -e "\n${LIME}${outputCreds}${NO_COLOR}"
        # Execute a kubectl command to trigger authentication to the cluster
        kubectl get namespaces
      else
        echo -e "\n${RED}${outputCreds}${NO_COLOR}"
      fi
    else
      echo -e "\n${YELLOW}Cluster \"${cluster}\" does not match pattern CON830700AKS*${NO_COLOR}"
    fi
  done
done

# Set back to DEV subscription
az account set -s "SAAS-8307-DEV"
