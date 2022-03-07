#!/bin/bash

# Script that help you to create secret in keyvault or in Kubernetes

set -e

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)

source "${SCRIPT_DIR}/library/nv_library.sh"

KEY_VAULT_DIR="${SCRIPT_DIR}/tmp/${SCRIPT_NAME}"
KUBE_SECRET_DIR="${SCRIPT_DIR}/tmp/${SCRIPT_NAME}/kube-secret"

# GLOBAL VARIABLES
allKeyVaults=""
selectedKeyVaults=()

## namespace
## keyvault
## context k8S
## download/upload regex

help=0
force=0
description_secret=""

ARGS=()

while [ $# -gt 0 ]; do
  unset OPTIND
  unset OPTARG

  while getopts hn:k:d:f:r:p options; do
    case ${options} in
      n)
        namespaces="${OPTARG}"
        ;;
      k)
        keyVaults="${OPTARG}"
        ;;
      d)
        description_secret="${OPTARG}"
        ;;
      f)
        force=1
        ;;
      r)
        regex="${OPTARG}"
        ;;
      p)
        prefix="${OPTARG}"
        ;;
      h)
        help=1
        ;;
      *)
        echo -e "\n${YELLOW}Unsupported option ${OPTARG}${NO_COLOR}"
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

# echo "ARGS: ${ARGS[@]}"
type=${ARGS[0]}

# Show current subscription and cluster
check_subscription
check_cluster

optionalText="${DEEP_SKY_BLUE}Theses OPTIONAL parameters can be added:${NO_COLOR}\n"
optionalText+="\t${DEEP_SKY_BLUE}- \"-n namespace1,namespace2\": Select the keyvault associate to \"namespace1\" and \"namespace2\" (example: \"-n compta-test,test-gi\"). You can only specify namespace or keyvault.${NO_COLOR}\n"
optionalText+="\t${DEEP_SKY_BLUE}- \"-k keyvault1,keyvault2\": Select the keyvault directly without asking you which one you want (example: \"-k SEC830700KVTD07-TEST-GI,SEC830700KVTD02-TEST\"). You can only specify namespace or keyvault. ${NO_COLOR}"

########################### CHECK PARAMS #################################
if [ "${type}" = "kube-secret" ]; then
  if [ ${#ARGS[@]} -eq 2 ] && [ ${help} -eq 0 ]; then
    kubeSecretName=${ARGS[1]}
  else
    echo -e "\nAdd secrets from a Key Vault to a Kubernetes secret.\n"
    echo -e "${RED}You need the following values:${NO_COLOR}"
    echo -e "\t${RED}- \"kubeSecretName\": which Kubernetes secret you want to put secrets (example: \"mongo-credentials\")${NO_COLOR}"
    echo -e "\t${RED}- \"-r regex\": take all secrets from Key Vault that begin with \"regex\" (example: \"-r mongo*\")${NO_COLOR}"
    echo -e "${optionalText}"
    echo -e "\t${DEEP_SKY_BLUE}- \"-p deletedPrefix\": It will delete the prefix for each secret from Key Vault in the Kubernetes secret (example: \"-p publicapi-\" publicapi-key-secret => key-secret)${NO_COLOR}"
    echo -e "\t${DEEP_SKY_BLUE}- \"-f\": force the recreation of the secret if it already exists.${NO_COLOR}"
    exit 1
  fi
elif [ "${type}" = "vault-secret" ]; then
  if [ ${#ARGS[@]} -eq 3 ] && [ ${help} -eq 0 ]; then
    name=${ARGS[1]}
    value=${ARGS[2]}
  else
    echo -e "\nAdd secrets to a Key Vault.\n"
    echo -e "${RED}You need the following values:${NO_COLOR}"
    echo -e "\t${RED}- \"name\" of the secret (example: mongo-uri-cache)${NO_COLOR}"
    echo -e "\t${RED}- \"value\" the value of the secret (example: http://mongo...com )${NO_COLOR}"
    echo -e "${optionalText}"
    exit 1
  fi
elif [ "${type}" = "delete-vault-secret" ]; then
  if [ ${#ARGS[@]} -eq 2 ] && [ ${help} -eq 0 ]; then
    name=${ARGS[1]}
  else
    echo -e "\nDelete secrets to a Key Vault.\n"
    echo -e "${RED}You need the following values:${NO_COLOR}"
    echo -e "\t${RED}- \"name\" of the secret (example: mongo-uri-cache)${NO_COLOR}"
    echo -e "${optionalText}"
    exit 1
  fi
elif [ "${type}" = "download" ]; then
  if [ ${#ARGS[@]} -ne 1 ] || [ ${help} -eq 1 ]; then
    echo -e "\nDownload all secrets from a Key Vault.\n"
    echo -e "${optionalText}"
    echo -e "\t${DEEP_SKY_BLUE}- \"-r regex\" can be use for downloading only some values\n${NO_COLOR}"
    exit 1
  fi
elif [ "${type}" = "upload" ]; then
  if [ ${#ARGS[@]} -ne 1 ] || [ ${help} -eq 1 ]; then
    echo -e "\nAdd secrets to a Key Vault.\n"
    echo -e "${optionalText}"
    echo -e "\t${DEEP_SKY_BLUE}- \"-r regex\" can be use for uploading only some values${NO_COLOR}"
    exit 1
  fi
else
  echo -e "\n${RED}Unknown type \"${type}\".\n${NO_COLOR}"
  echo -e "${RED}\"type\":\n\t- download\n\t- upload\n\t- vault-secret\n\t- delete-vault-secret\n\t- kube-secret${NO_COLOR}"
  exit 1
fi

select_key_vault "${namespaces}" "${keyVaults}"
script_name=$(basename "${BASH_SOURCE[0]}")
execution_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
default_description="Last updated by $(get_name_user) with ${script_name} at ${execution_date}"

##########################################################################
########################### VAULT SECRET #################################
##########################################################################
if [ "${type}" = "vault-secret" ]; then
  for keyVault in "${selectedKeyVaults[@]}"; do
    echo -e "\n${DEEP_SKY_BLUE}Begin ${type}: ${keyVault}${NO_COLOR}\n"

    description="${default_description}"
    # Update default description with specific description
    if [ "${description_secret}" != "" ]; then
      description="${description_secret}"
    fi

    # echo az keyvault secret set --vault-name "${keyVault}" --name "${name}" --value "${value}" --description "${description}"
    if az keyvault secret set --vault-name "${keyVault}" --name "${name}" --value "${value}" --description "${description}"; then
      echo -e "\n${LIME}Value inserted in Key Vault ${keyVault}${NO_COLOR}"
    else
      echo -e "\n${RED}Error with the cmd:\n${NO_COLOR}"
      echo -e "\t${RED}az keyvault secret set --vault-name \"${keyVault}\" --name \"${name}\" --value \"${value}\" --description \"${description}\"${NO_COLOR}"
    fi

    echo -e "\n${DEEP_SKY_BLUE}End ${type}: ${keyVault}${NO_COLOR}"
  done
elif [ "${type}" = "delete-vault-secret" ]; then
  for keyVault in "${selectedKeyVaults[@]}"; do
    echo -e "\n${DEEP_SKY_BLUE}Begin ${type}: ${keyVault}${NO_COLOR}\n"
    secretNames=($(az keyvault secret list --vault-name "${keyVault}" | jq -r '.[] | select(.name | test("^'"${name}"'")) | .name'))
    if [ ${#secretNames[@]} -eq 1 ]; then
      echo -e "az keyvault secret delete --name \"${name}\" -vault-name \"${keyVault}\""
      az keyvault secret delete --name "${name}" --vault-name "${keyVault}"
    fi
    echo -e "\n${DEEP_SKY_BLUE}End ${type}: ${keyVault}${NO_COLOR}"
  done

##########################################################################
########################## KUBE SECRET ###################################
##########################################################################
elif [ "${type}" = "kube-secret" ]; then
  for keyVault in "${selectedKeyVaults[@]}"; do
    echo -e "\n${DEEP_SKY_BLUE}Begin ${type}: ${keyVault}${NO_COLOR}"

    # Get namespaces from Key Vault's tags
    namespacesKeyVault=($(echo "${allKeyVaults}" | jq -r '.[] | select(.name | test("'"${keyVault}"'")) | .tags.namespace' | tr "," " "))
    # Get all secrets that begins with "${regex}"
    secretNames=($(az keyvault secret list --vault-name "${keyVault}" | jq -r '.[] | select(.name | test("^'"${regex}"'")) | .name'))

    filteredNamespaces=()
    # Filter namespaces present in Key Vault tag namespace and in selected namespaces option (-n)
    if [ ${#namespaces[@]} -ne 0 ]; then
      for namespace in "${namespacesKeyVault[@]}"; do
        if [[ "${namespaces[*]}" == *"${namespace}"* ]]; then
          filteredNamespaces+=("${namespace}")
        fi
      done
    # No selected namespaces option (-n), take all namespaces in Key Vault tag namespace
    else
      filteredNamespaces=("${namespacesKeyVault[@]}")
    fi

    # Check if secrets match the regex to avoid create an empty secret in K8s
    if [ ${#secretNames[@]} -ne 0 ]; then
      # Ask for namespaces if no tag namespace found
      if [ "${filteredNamespaces[*]}" = "null" ] || [ "${filteredNamespaces[*]}" = "" ]; then
        filteredNamespaces=()
        echo -e "\n${YELLOW}You must add the \"namespace\" tag to the Key Vault ${keyVault}${NO_COLOR}\n"
        read -r -p "Select namespaces where to create the secret (separated by spaces): " -a input

        for namespaceInput in "${input[@]}"; do
          case ${namespaceInput} in
            [nN][Oo])
              echo -e "\nExit"
              exit 1
              ;;
            *)
              # Add new element at the end of the array
              filteredNamespaces[${#filteredNamespaces[@]}]="${namespaceInput}"
              ;;
          esac
        done
      fi

      cmdArgs=()
      annotations=""

      # Create a temporary folder to save all secrets contained in "${secretNames}"
      rm -rf "${KUBE_SECRET_DIR}"
      mkdir -p "${KUBE_SECRET_DIR}"

      # Get all existing namespaces in K8s cluster
      existingNamespacesStr=$(kubectl get namespace -o json | jq -r '[ .items[].metadata.name ] | join(" ")')
      # Build a filtered array namespaces
      filteredNamespacesK8s=()
      for namespace in "${filteredNamespaces[@]}"; do
        if [[ "${existingNamespacesStr}" == *"${namespace}"* ]]; then
          filteredNamespacesK8s+=("${namespace}")
        fi
      done

      echo -e "\n${PINK}Namespaces selected after filter: ${#filteredNamespacesK8s[*]} (${filteredNamespacesK8s[*]})${NO_COLOR}"

      # Ask before doing a terrible mistake!
      echo ""
      confirm "Are you sure you want to create this secret in K8s on ${#filteredNamespacesK8s[@]} namespace(s) (${filteredNamespacesK8s[*]})? [y/N]"

      # Do nothing if no namespaces after filtering
      if [ ${#filteredNamespacesK8s[@]} -ne 0 ]; then
        # Download secrets
        for secretName in "${secretNames[@]}"; do
          echo -e "\tDownload secret from Key Vault: ${secretName}"

          # echo az keyvault secret download --vault-name "${keyVault}" --name "${secretName}" -f "${KUBE_SECRET_DIR}/${secretName}"
          az keyvault secret download --vault-name "${keyVault}" --name "${secretName}" -f "${KUBE_SECRET_DIR}/${secretName}"
          # Delete prefix
          secretNameCleanUPPER="${secretName#"${prefix}"}"
          # To upper and replace dashes (-) with underscores (_)
          secretNameCleanUPPER=$(echo "${secretNameCleanUPPER//-/_}" | tr "[:lower:]" "[:upper:]")
          echo -e "\t\tSecret name in Kubernetes: ${secretNameCleanUPPER}\n"

          # Build command's args with the secret and its value
          cmdArgs+=(--from-file="${secretNameCleanUPPER}=${KUBE_SECRET_DIR}/${secretName}")
          uri=$(az keyvault secret show --vault-name "${keyVault}" --name "${secretName}" --query=id)
          # Annotation keys are limited to 64 characters
          name="uri-${secretName}"
          annotations="${annotations}, \"${name:0:63}\": ${uri}"
        done

        # Create secret for all namespaces filtered for the current Key Vault
        for namespace in "${filteredNamespacesK8s[@]}"; do
          if [ "${force}" = "1" ]; then
            echo -e "\nkubectl create secret generic --save-config --dry-run=client ${kubeSecretName} -n ${namespace} ***** -o yaml | kubectl apply -f -"
            message=$(kubectl create secret generic --save-config --dry-run=client "${kubeSecretName}" -n "${namespace}" "${cmdArgs[@]}" -o yaml | kubectl apply -f - 2>&1)
          else
            echo -e "\nkubectl create secret generic ${kubeSecretName} -n ${namespace} *****"
            message=$(kubectl create secret generic --save-config "${kubeSecretName}" -n "${namespace}" "${cmdArgs[@]}" 2>&1)
          fi

          if [ "${message}" = "secret/${kubeSecretName} created" ] || [ "${message}" = "secret/${kubeSecretName} configured" ]; then
            echo -e "${DEEP_SKY_BLUE}${message}${NO_COLOR}\n"
            # "app": "test",
            jsonPatch='{
              "metadata": {
                "labels": {
                  "type": "app-config"
                },
                "annotations": {
                    "created/at": "'${execution_date}'",
                    "created/by": "'$(get_name_user)'",
                    "created/with": "'${script_name}'",
                    "script-url": "https://dev.azure.com/cegid/Loop/_git/Loop-DevOps?path=%2Fscripts%2Fsh%2F'${script_name}'&version=GBbetterBash&_a=contents"
                    '${annotations}'
                }
              }
            }'

            jsonPatch=$(echo "${jsonPatch}" | jq -c .)
            echo -e "kubectl patch secret -n ${namespace} ${kubeSecretName} -p ${jsonPatch}"
            kubectl patch secret -n "${namespace}" "${kubeSecretName}" -p "${jsonPatch}"
          else
            echo -e "${RED}${message}${NO_COLOR}\n"
          fi
        done
      else
        echo -e "\n${YELLOW}No namespace found after filtering to create secret in cluster.${NO_COLOR}"
      fi

      # Delete temporary folder
      rm -rf "${KUBE_SECRET_DIR}"
    else
      echo -e "\n${YELLOW}No values found for this Key Vault: ${keyVault}${NO_COLOR}"
    fi

    echo -e "\n${DEEP_SKY_BLUE}End ${type}: ${keyVault}${NO_COLOR}"
  done

##########################################################################
########################## UPLOAD SECRET ###############################
##########################################################################
elif [ "${type}" = "upload" ]; then
  # Upload
  for keyVault in "${selectedKeyVaults[@]}"; do
    echo -e "\n${DEEP_SKY_BLUE}Begin ${type}: ${keyVault}${NO_COLOR}\n"

    if [ -d "${KEY_VAULT_DIR}/${keyVault}" ]; then
      files=($(find "${KEY_VAULT_DIR}/${keyVault}" -type f -name "${regex}*"))
      if [ ${#files[@]} -eq 0 ]; then
        echo -e "${RED}No file found with regex \"${regex}*\" in ${KEY_VAULT_DIR}/${keyVault}${NO_COLOR}"
      else
        for file in "${files[@]}"; do
          name="${file#"${KEY_VAULT_DIR}/${keyVault}/"}"
          echo -e "Creating secret ${name}...\n"
          # echo az keyvault secret set --vault-name "${keyVault}" --name "${name}" --file "${file}" --description "${default_description}"
          if az keyvault secret set --vault-name "${keyVault}" --name "${name}" --file "${file}" --description "${default_description}"; then
            echo -e "\n${LIME}Value inserted in Key Vault ${keyVault}${NO_COLOR}"
          else
            echo -e "${RED}Error with the cmd:\n${NO_COLOR}"
            echo -e "\t${RED}az keyvault secret set --vault-name \"${keyVault}\" --name \"${name}\" --file \"${file}\" --description \"${default_description}\"${NO_COLOR}"
          fi
        done
      fi
    else
      echo -e "${RED}Directory ${KEY_VAULT_DIR}/${keyVault} does not exist in your workspace.${NO_COLOR}"
    fi

    echo -e "\n${DEEP_SKY_BLUE}End ${type}: ${keyVault}${NO_COLOR}"
  done

##########################################################################
########################### DOWNLOAD SECRET ##############################
##########################################################################
elif [ "${type}" = "download" ]; then
  # Download
  for keyVault in "${selectedKeyVaults[@]}"; do
    echo -e "\n${DEEP_SKY_BLUE}Begin ${type}: ${keyVault}${NO_COLOR}\n"

    # Get all secrets that begins with "${regex}"
    secretNames=($(az keyvault secret list --vault-name "${keyVault}" | jq -r '.[] | select(.name | test("^'"${regex}"'")) | .name'))
    # Create a folder to save all secrets contained in "${secretNames}"
    mkdir -p "${KEY_VAULT_DIR}/${keyVault}"

    for secretName in "${secretNames[@]}"; do
      echo -e "\tDownload secret from Key Vault: ${secretName}"

      # echo az keyvault secret download --vault-name "${keyVault}" --name "${secretName}" -f "${KEY_VAULT_DIR}/${keyVault}/${secretName}"
      az keyvault secret download --vault-name "${keyVault}" --name "${secretName}" -f "${KEY_VAULT_DIR}/${keyVault}/${secretName}"
    done
    echo -e "\n${DEEP_SKY_BLUE}End ${type}: ${keyVault}${NO_COLOR}"
  done
else
  echo -e "${RED}ERROR${NO_COLOR}"
fi
