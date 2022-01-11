#!/bin/bash

# Prerequisites: You must install azure-cli and jq

set -e

# Colors
blue="\033[0;34m"
green="\033[0;32m"
red="\033[0;31m"
yellow="\033[0;33m"
nc="\033[0m" # No Color

is_connect_with_az_cli() { if [ "$(az account list 2> /dev/null)" = "[]" ]; then az login; fi }
is_subscription_known_by_user() { if [ "$(az account list | jq ".[] | select(.name == \"$1\") | .name")" = "" ]; then echo "1"; else echo "0"; fi }

# Trigger az login if not connected
is_connect_with_az_cli

# Subscriptions
subscriptions=(
  "App-Yupana" # Old dev subscription
  "SAAS-8307-DEV"
  "SAAS-8307-INTE"
  "SAAS-8307-PROD"
)

for subscription in "${subscriptions[@]}"; do
  echo -e "\n***** Subscription ${subscription} *****"

  # Ignore the subscription if it is not known by the user
  if [ "$(is_subscription_known_by_user "${subscription}")" = "1" ]; then
    echo -e "\n${red}You do not have acces to this subscription.${nc}"
    continue
  fi

  # Connect to the subscription
  az account set -s "${subscription}"

  # Clusters defined in the selected subscription
  clusters=($(az aks list | jq -r '.[].name'))
  # Stop here if there is not cluster for this subscription
  if [ ${#clusters[@]} -eq 0 ]; then
    echo -e "\n${blue}No cluster found${nc}"
    continue
  fi

  for cluster in "${clusters[@]}" ; do
    # Accept only cluster with "CON830700AKS*" pattern
    if [[ ${cluster} == CON830700AKS* ]]; then
      echo -e "\n${blue}Cluster: ${cluster}${nc}"
      resourceGroup=$(az aks list | jq -r ".[] | select(.name == \"${cluster}\") | .resourceGroup")
      echo -e "${blue}Resource Group: ${resourceGroup}${nc}"

      # Disable exit on error only for next command
      set +e
      outputCreds=$(az aks get-credentials -g "${resourceGroup}" -n "${cluster}" --overwrite-existing 2>&1)
      resultCreds=$?
      set -e

      # Write in green if OK, in red if it is not
      if [ ${resultCreds} -eq 0 ]; then
        echo -e "\n${green}${outputCreds}${nc}"
      else
        echo -e "\n${red}${outputCreds}${nc}"
      fi
    else
      echo -e "\n${yellow}Cluster \"${cluster}\" does not match pattern CON830700AKS*${nc}"
    fi
  done
done

# Set back to DEV subscription
az account set -s "SAAS-8307-DEV"
