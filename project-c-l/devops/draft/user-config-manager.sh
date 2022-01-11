#!/bin/bash

# shellcheck disable=SC2214

set -e

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)
STORE_FOLDER="${SCRIPT_DIR}/../tmp/${SCRIPT_NAME}"

################################################################################
## Examples:
##
## ./user-config-manager.sh --mode=copy \
##   --services=cae-ecriture,cae-external-accounting,cae-initialisation,importrelevedsp2 \
##   --namespace-source=current \
##   --namespace-target=loop-cae
##
## ./user-config-manager.sh --mode=copy \
##   --services=cae-ecriture,cae-external-accounting,cae-initialisation,importrelevedsp2 \
##   --namespace-source=current \
##   --namespace-target=beta \
##   --hostname-source=loop.loopsoftware.fr \
##   --hostname-target=beta.loopsoftware.fr
##
## ./user-config-manager.sh --mode=paste \
##   --services=cae-ecriture,cae-external-accounting,cae-initialisation,importrelevedsp2 \
##   --namespace-target=loop-cae
################################################################################

################################################################################
## Options and arguments
################################################################################

# complain to STDERR and exit with error
die() {
  echo "$*" >&2
  exit 2
}
needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option"; fi; }

SHOW_HELP=0
while getopts hm:-: OPT; do
  # support long options: https://stackoverflow.com/a/28466267/519360
  if [ "${OPT}" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"         # extract long option name
    OPTARG="${OPTARG#"${OPT}"}" # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"        # if long option argument, remove assigning `=`
  fi
  case "${OPT}" in
    h | help)
      SHOW_HELP=1
      ;;
    hostname-source)
      needs_arg
      HOSTNAME_SOURCE="${OPTARG}"
      ;;
    hostname-target)
      needs_arg
      HOSTNAME_TARGET="${OPTARG}"
      ;;
    m | mode)
      needs_arg
      MODE="${OPTARG}"
      ;;
    namespace-source)
      needs_arg
      NAMESPACE_SOURCE="${OPTARG}"
      ;;
    namespace-target)
      needs_arg
      NAMESPACE_TARGET="${OPTARG}"
      ;;
    services)
      needs_arg
      IFS=',' read -r -a SERVICES <<< "${OPTARG}"
      ;;
    ??*)
      # Bad long option
      die "Illegal option --${OPT}"
      ;;
    ?)
      # Bad short option (error reported via getopts)
      exit 2
      ;;
  esac
done
# Remove parsed options and args from $@ list
shift $((OPTIND - 1))

if [ ${SHOW_HELP} -eq 1 ]; then
  echo -e "\n${BASH_SOURCE[0]} --mode=copy|paste
  --services=service1,service2,...
  [--hostname-source=<hostname>]
  [--hostname-source=<hostname>]
  --namespace-source=<namespace>
  --namespace-source=<namespace>
  [-h | --help]"
  exit 0
fi

################################################################################
## Functions
################################################################################

copy() {
  echo "Copy secret user-config-$1 from namespace ${NAMESPACE_SOURCE} to ${STORE_FOLDER}/user-config-$1.json"

  # Remove some metadata and annotations + replace namespace source with namespace target
  user_config_secret=$(kubectl get secret "user-config-$1" -n "${NAMESPACE_SOURCE}" -o json \
    | jq 'del(.metadata.managedFields, .metadata.uid, .metadata.creationTimestamp, .metadata.resourceVersion, .metadata.selfLink)' \
    | jq '.metadata.annotations |= {}' \
    | jq ".metadata.namespace |= sub(\"${NAMESPACE_SOURCE}\"; \"${NAMESPACE_TARGET}\")")

  echo "${user_config_secret}" > "${STORE_FOLDER}/user-config-$1.json"
}

paste() {
  echo "Apply ${STORE_FOLDER}/user-config-$1.json to namespace ${NAMESPACE_TARGET}"

  # Decrypt user-config secret data
  user_config_data=$( (jq -r '.data["user-config.json"]' | base64 -d) < "${STORE_FOLDER}/user-config-$1.json")

  # Replace hostname source with hostname target
  if [ -n "${HOSTNAME_SOURCE}" ] && [ -n "${HOSTNAME_TARGET}" ]; then
    echo "Update hostnames"
    user_config_data="${user_config_data//${HOSTNAME_SOURCE}/${HOSTNAME_TARGET}}"
  fi

  # Encode in base 64 user-config secret data
  user_config_data_base64=$(echo "${user_config_data}" | base64)

  # Update file with new data encoded in base 64
  (jq ".data[\"user-config.json\"]=\"${user_config_data_base64}\"" | kubectl apply -f -) < "${STORE_FOLDER}/user-config-$1.json"
}

################################################################################
## Main
################################################################################

echo -e "\nNumber of services: ${#SERVICES[@]}\n"

# Handle action depending on the mode
if [ ${#SERVICES[@]} -ne 0 ]; then
  # Copy from namespace source to namespace target all user-config for provided services to user-config-<service_name>.json files by replacing hostname source with hostname target
  if [ "${MODE}" = "copy" ]; then
    # Delete folder if it exists
    if [ -e "${STORE_FOLDER}" ] && [ -d "${STORE_FOLDER}" ]; then
      rm -rf "${STORE_FOLDER}"
    fi
    # Create folder
    if [ ! -e "${STORE_FOLDER}" ]; then
      mkdir -p "${STORE_FOLDER}"
    fi

    echo -e "Copy all user-config for provided services from namespace ${NAMESPACE_TARGET} to namespace ${NAMESPACE_TARGET} to ${BASH_SOURCE[0]}/user-config-*.json files\n"
    for SERVICE in "${SERVICES[@]}"; do
      copy "${SERVICE}"
    done
  # Apply all user-config-<service_name>.json files to namespace target
  elif [ "${MODE}" = "paste" ]; then
    echo -e "Apply all ${BASH_SOURCE[0]}/user-config-*.json to namespace ${NAMESPACE_TARGET}\n"
    for SERVICE in "${SERVICES[@]}"; do
      paste "${SERVICE}"
    done

    # Delete folder if it exists
    if [ -e "${STORE_FOLDER}" ] && [ -d "${STORE_FOLDER}" ]; then
      rm -rf "${STORE_FOLDER}"
    fi
  fi
fi
