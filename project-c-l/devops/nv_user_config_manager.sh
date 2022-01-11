#!/bin/bash

# shellcheck disable=SC2206

set -e

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)
STORE_FOLDER="${SCRIPT_DIR}/tmp/${SCRIPT_NAME}"

source "${SCRIPT_DIR}/library/nv_library.sh"

# Handle arguments
ARGS=()

while [ $# -gt 0 ]; do
  unset OPTIND
  unset OPTARG

  while getopts hn:k:c:r:s:p:f options; do
    case ${options} in
      n)
        namespaces=("${OPTARG}")
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

# Mode is first argument that is not an option
mode="${ARGS[0]}"
if [ "${mode}" = "store" ]; then
  info "Store user-config locally\n"

  # Remove old user-config
  rm -rf "${STORE_FOLDER}"
  mkdir -p "${STORE_FOLDER}"
elif [ "${mode}" = "create" ]; then
  info "Create user-config in K8s\n"
elif [ "${mode}" = "" ]; then
  error "Mode is mandatory"
  exit 1
else
  warn "Unknown mode ${mode}\n"
  exit 1
fi

# Get all namespaces if non has been filled
if [ ${#namespaces[@]} -eq 1 ]; then
  info "Namespace ${namespaces[0]}\n"
else
  info "All namespaces\n"
  namespaces=(${NV_NAMESPACES})
fi

# Main program
for namespace in "${namespaces[@]}"; do
  info "Namespace ${namespace}\n"

  secrets=($(kubectl get secret -n "${namespace}" -o json | jq -r '.items[].metadata.name | select(.|test("user-config*")) | .'))

  if [ ${#secrets[@]} -eq 0 ]; then
    info "No user-config secrets found\n"
  else
    # Create namespace folder only in store mode
    if [ "${mode}" = "store" ]; then
      mkdir -p "${STORE_FOLDER}/${namespace}"
    fi

    for secret_name in "${secrets[@]}"; do
      filename="${secret_name}.json"

      if [ "${mode}" = "store" ]; then
        # Store user-config
        echo -e "Store user-config ${secret_name} in ${STORE_FOLDER}/${namespace}/${filename}"
        kubectl get secret "${secret_name}" -n "${namespace}" -o json | jq -r '.data["user-config.json"]' | base64 -d | jq -S '.' > "${STORE_FOLDER}/${namespace}/${filename}"
      elif [ "${mode}" = "create" ]; then
        # Create user-config
        echo -e "Create user-config ${secret_name} to ${namespace} from ${STORE_FOLDER}/${namespace}/${filename}"
        kubectl create secret generic --save-config --dry-run=client "${secret_name}" -n "${namespace}" --from-file=user-config.json="${STORE_FOLDER}/${namespace}/${filename}" -o yaml | kubectl apply -f -
      fi
    done
  fi
done
