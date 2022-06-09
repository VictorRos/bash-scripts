#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

source "${SCRIPT_DIR}/library/nv_library.sh"

############################################################################################
#######################             Execute mongodb query on some           ################
####################### Cluster for dev/int/prod with secret url credential ################
############################################################################################

# GLOBAL VARIABLES
allKeyVaults=""
selectedKeyVaults=()

# Handle arguments
help=0
debug=false
ARGS=()

while [ $# -gt 0 ]; do
  unset OPTIND
  unset OPTARG

  while getopts hdn:k: options; do
    case ${options} in
      n)
        namespaces="${OPTARG}"
        ;;
      k)
        keyVaults="${OPTARG}"
        ;;
      d)
        debug=true
        ;;
      h)
        help=1
        ;;
      *)
        warn "Unsupported option ${OPTARG}\n"
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

########################### CHECK PARAMS #################################
if [ ${#ARGS[@]} -eq 2 ] && [ ${help} -eq 0 ]; then
  file=${ARGS[0]}
  secretNameStr=${ARGS[1]}
else
  echo -e "\nExecute a script in MongoDB.\n"
  echo -e "${RED}You need the following values:${NO_COLOR}"
  echo -e "${RED}\t- \"File\": File path that contains the MongoDB query (example: _query.js)${NO_COLOR}"
  echo -e "${RED}\t- \"Secret name\": String to match secret name to get MongoDB connection string from Key Vault (example: mongo-credentials-mongo-uri-ypn-cache, mongo-credentials-mongo-uri-ypn-bigdata)${NO_COLOR}"
  echo -e "${DODGER_BLUE}Theses OPTIONAL parameters can be added:${NO_COLOR}"
  echo -e "${DODGER_BLUE}\t- \"-n namespace1,namespace2\": Select the keyvault associate to \"namespace1\" and \"namespace2\" (example: \"-n compta-test,iso-prod\"). You can only specify namespace or keyvault.${NO_COLOR}"
  echo -e "${DODGER_BLUE}\t- \"-k keyvault1,keyvault2\": Select the keyvault directly without asking you which one you want (example: \"-k SEC830700KVTD02-TEST,SEC830700KVTD18-ISO-PROD\"). You can only specify namespace or keyvault.${NO_COLOR}"
  exit 1
fi

# Show subscription and cluster
check_subscription
check_cluster

select_key_vault "${namespaces}" "${keyVaults}"

mongoScript=$(cat "${file}")

for keyVault in "${selectedKeyVaults[@]}"; do
  echo -e "\n${DODGER_BLUE}Begin ${keyVault}${NO_COLOR}\n"

  # Get namespaces from Key Vault's tags
  namespacesTagged=$(echo "${allKeyVaults}" | jq -r '.[] | select(.name|test("'"${keyVault}"'")) | .tags.namespace')
  # Get all secrets that begins with "$regex"
  secretNames=($(az keyvault secret list --vault-name "${keyVault}" | jq -r '.[] | select(.name|test("'"${secretNameStr}"'")) | .name'))

  echo "Namespaces found: ${namespacesTagged}"
  if [ "${namespacesTagged}" != "null" ] && [ "${namespacesTagged}" != "" ]; then
    for secretName in "${secretNames[@]}"; do
      echo -e "\tDownload secret from Key Vault: ${secretName}"

      # echo az keyvault secret show --vault-name "${keyVault}" --name "${secretName}" | jq -r '.value'
      connectionString=$(az keyvault secret show --vault-name "${keyVault}" --name "${secretName}" | jq -r '.value')

      username=$(echo "${connectionString}" | sed -rn "s/.*\/\/([^:]*):.*@.*/\1/p")
      password=$(echo "${connectionString}" | sed -rn "s/.*\/\/[^:]*:(.*)@.*/\1/p")
      url=$(echo "${connectionString}" | sed -rn "s/(.*\/\/)[^:]*:.*@(.*)/\1\2/p")

      # Execute script in MongoDB
      if [ "${debug}" = "true" ]; then
        echo mongosh "${url}" --username "${username}" --password "${password}" --eval "${mongoScript}"
      fi
      mongosh "${url}" --username "${username}" --password "${password}" --eval "${mongoScript}"
    done
  else
    error "You need to add \"namespace\" tag to the Key Vault ${keyVault}"
  fi

  echo -e "\n${DODGER_BLUE}End ${keyVault}${NO_COLOR}"
done
