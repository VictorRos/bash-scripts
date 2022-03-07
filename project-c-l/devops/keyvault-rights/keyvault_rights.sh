#!/bin/bash

# Script that help you to create secret in keyvault or in Kubernetes

set -e

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

source "${SCRIPT_DIR}/../library/nv_library.sh"

RIGHTS_FILE="${SCRIPT_DIR}/rights.json"

###########################################  PARAMETERS  ###########################################

help=false
dryRun=false
selectedGroups=()
selectedKeyVaults=()
ARGS=()

while [ $# -gt 0 ]; do
  unset OPTIND
  unset OPTARG

  while getopts hdk:g: options; do
    case ${options} in
      d)
        dryRun=true
        ;;
      g)
        IFS=',' read -r -a selectedGroups <<< "${OPTARG}"
        ;;
      k)
        IFS=',' read -r -a selectedKeyVaults <<< "${OPTARG}"
        ;;
      h)
        help=true
        ;;
      *)
        warn "\nUnsupported option ${OPTARG}"
        exit 1
        ;;
    esac
  done
  shift $((OPTIND - 1))
  # Avoid adding an empty arg
  if [ "$1" != "" ]; then ARGS+=("$1"); fi
  # Avoid script to fail with no errors because we shift empty remaining args
  if [ $# -gt 0 ]; then shift; fi
done

####################################################################################################

# Show help and exit
if [ "${help}" = "true" ]; then
  info "OPTIONAL parameters:"
  info "    -g groupName1,groupName2 : Azure AD groups (example: -k SEC830700KVTD02-TEST,SEC830700KVTD07-TEST-GI)"
  info "    -k keyVault1,keyVault2 : Key Vaults (example: -k SEC830700KVTD02-TEST,SEC830700KVTD07-TEST-GI)"
  info "    -d : Dry run (do not run commands, just show logs)"
  info "    -h : Show help"
  exit 0
fi

# Trigger az login if not connected
is_connect_with_az_cli

# Encode object with base64 because bash split string on spaces, and objects contain spaces :'(
groups=($(jq -r '.groups[] | @base64' "${RIGHTS_FILE}"))

for group in "${groups[@]}"; do
  # Decode object
  groupDecoded=$(echo "${group}" | base64 -d)

  groupName=$(echo "${groupDecoded}" | jq -r '.name')
  groupID=$(echo "${groupDecoded}" | jq -r '.id')

  info "\nGroup ${groupName} (${groupID})"

  # Got to next Azure AD Group if list is not empty and Azure AD Group is not in the list
  if [ "${selectedGroups[*]}" != "" ] && ! printf '%s\n' "${selectedGroups[@]}" | grep -Fxq "${groupName}"; then
    echo -e "\n${YELLOW}Do nothing${NO_COLOR}"
    continue
  fi

  # Encode object with base64 because bash split string on spaces, and objects contain spaces :'(
  keyVaults=($(echo "${groupDecoded}" | jq -r '.keyVaults[] | @base64'))
  for keyVault in "${keyVaults[@]}"; do
    keyVaultDecoded=$(echo "${keyVault}" | base64 -d)

    keyVaultName=$(echo "${keyVaultDecoded}" | jq -r '.name')
    keyVaultSubscription=$(echo "${keyVaultDecoded}" | jq -r '.subscription')
    keyVaultResourceGroup=$(echo "${keyVaultDecoded}" | jq -r '.resourceGroup')
    keyVaultCertificatePermissions=()
    IFS=' ' read -r -a keyVaultCertificatePermissions <<< "$(echo "${keyVaultDecoded}" | jq -r '.certificatePermissions')"
    keyVaultKeyPermissions=()
    IFS=' ' read -r -a keyVaultKeyPermissions <<< "$(echo "${keyVaultDecoded}" | jq -r '.keyPermissions')"
    keyVaultSecretPermissions=()
    IFS=' ' read -r -a keyVaultSecretPermissions <<< "$(echo "${keyVaultDecoded}" | jq -r '.secretPermissions')"

    # Got to next Key Vault if list is not empty and Key Vault is not in the list
    if [ "${selectedKeyVaults[*]}" != "" ] && ! printf '%s\n' "${selectedKeyVaults[@]}" | grep -Fxq "${keyVaultName}"; then
      continue
    fi

    echo -e "\nUpdate Key Vault ${LIME}${keyVaultName}${NO_COLOR} rights from resource group ${LIME}${keyVaultResourceGroup}${NO_COLOR} (${LIME}${keyVaultSubscription}${NO_COLOR})"
    echo -e "  - Certificate permissions: ${SALMON}${keyVaultCertificatePermissions[*]}${NO_COLOR}"
    echo -e "  - Key permissions: ${SALMON}${keyVaultKeyPermissions[*]}${NO_COLOR}"
    echo -e "  - Secret permissions: ${SALMON}${keyVaultSecretPermissions[*]}${NO_COLOR}"

    # Execute commands?
    if [ "${dryRun}" = "false" ]; then
      echo -e "Delete old rights (if existing)"
      # Delete old rights
      az keyvault delete-policy \
        --name "${keyVaultName}" \
        --subscription "${keyVaultSubscription}" \
        --resource-group "${keyVaultResourceGroup}" \
        --object-id "${groupID}" \
        --output none \
        --verbose || true

      echo -e "Create new rights"
      # Create new rights
      az keyvault set-policy \
        --name "${keyVaultName}" \
        --subscription "${keyVaultSubscription}" \
        --resource-group "${keyVaultResourceGroup}" \
        --object-id "${groupID}" \
        --certificate-permissions "${keyVaultCertificatePermissions[@]}" \
        --key-permissions "${keyVaultKeyPermissions[@]}" \
        --secret-permissions "${keyVaultSecretPermissions[@]}" \
        --output none \
        --verbose
    fi
  done
done
