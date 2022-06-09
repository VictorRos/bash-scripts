#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/nv_color.sh"

################################################################################
#                                   Utils                                      #
################################################################################

join_arr() {
  local IFS="$1"
  shift
  echo "$*"
}

################################################################################
#                             Global variables                                 #
################################################################################

# Ignore technical namespaces
export NV_NAMESPACES_TO_IGNORE=(
  "backup-victoria"
  "collectorforkubernetes"
  "default"
  "dynatrace"
  "jenkins"
  "keda"
  "kuard"
  "kube-node-lease"
  "kube-public"
  "kube-system"
  "kubecost"
  "kuberhealthy"
  "memcached"
  "monitoring"
  "network"
  "optimmo2"
  "perf"
  "redis"
  "starboard"
  "weave"
)
# For jq <3
NV_NAMESPACES_TO_IGNORE_FOR_JQ=$(join_arr "|" "${NV_NAMESPACES_TO_IGNORE[@]}")
export NV_NAMESPACES_TO_IGNORE_FOR_JQ

# Current subscription
NV_SUBSCRIPTION=$(az account show | jq -r '.name')
export NV_SUBSCRIPTION

# Current cluster
NV_CLUSTER=$(kubectl config current-context || true)
export NV_CLUSTER

# Namespaces for current cluster
NV_NAMESPACES=($(kubectl get namespace -o json | jq '[.items[].metadata.name] | map(select(test("'"${NV_NAMESPACES_TO_IGNORE_FOR_JQ}"'") == false))' | jq -r '.[]' || true))
export NV_NAMESPACES

################################################################################
#                                  Private                                     #
################################################################################

color_subscription() {
  local text=$1

  local color=${LIME}

  if [[ "${NV_SUBSCRIPTION}" == *"-INTE"* ]]; then
    color=${YELLOW}
  elif [[ "${NV_SUBSCRIPTION}" == *"-PROD"* ]]; then
    color=${ORANGE_RED}
  fi

  echo -e "${color}${text}${NO_COLOR}"
}

color_cluster() {
  local text=$1

  local color=${LIME}

  if [[ "${NV_CLUSTER}" == *"AKSI0"* ]]; then
    color=${YELLOW}
  elif [[ "${NV_CLUSTER}" == *"AKS00"* ]]; then
    color=${ORANGE_RED}
  fi

  echo -e "${color}${text}${NO_COLOR}"
}

################################################################################
#                             Public (exported)                                #
################################################################################

info() {
  echo -e "${DODGER_BLUE}$1${NO_COLOR}"
}
warn() {
  echo -e "${YELLOW}$1${NO_COLOR}"
}
error() {
  echo -e "${RED}$1${NO_COLOR}"
}

confirm() {
  read -rp $"${1:-"\nAre you sure? [y/N]"} " response
  case "${response}" in
    [yY][eE][sS] | [yY])
      true
      ;;
    *)
      false
      ;;
  esac
}

check_subscription() {
  color_subscription "Use subscription: ${NV_SUBSCRIPTION}"
}

check_cluster() {
  color_cluster "Use K8S cluster: ${NV_CLUSTER}"
}

get_name_user() {
  az account show | jq -r '.user.name'
}

is_connect_with_az_cli() {
  if [ "$(az account list 2> /dev/null)" = "[]" ]; then
    az login
  fi
}

is_subscription_known_by_user() {
  if [ "$(az account list | jq ".[] | select(.name == \"$1\") | .name")" = "" ]; then
    echo "1"
  else
    echo "0"
  fi
}

# Create the following global variables
# - ${allKeyVaults} : string
# - ${selectedKeyVaults} : array
select_key_vault() {
  local namespaces=$1
  local keyVaults=$2
  local subscription=$3

  if [ "${subscription}" == "" ]; then
    subscription=$(az account show | jq -r '.name')
  fi
  ########################### CHECK VAULT #################################
  allKeyVaults=$(az keyvault list | jq -r 'map(select(.name | test("SEC830700KVT"))) | sort_by(.name)')
  local keyVaultNames=($(echo "${allKeyVaults}" | jq -r '.[].name'))

  # Select Key Vaults from Key Vaults option
  if [ -n "${keyVaults}" ]; then
    local keyVaultTestRegex
    keyVaultTestRegex=$(echo "${keyVaults}" | tr "," "|")

    selectedKeyVaults=($(echo "${allKeyVaults}" | jq -r '.[] | select(.name | test("'"${keyVaultTestRegex}"'")) | .name'))
  # Select Key Vaults from namespaces option
  elif [ -z "${keyVaults}" ] && [ -n "${namespaces}" ]; then
    local namespaceTestRegex
    namespaceTestRegex=$(echo "${namespaces}" | tr "," "|")

    selectedKeyVaults=($(echo "${allKeyVaults}" | jq -r '.[] | select(.tags.namespace != null) | select(.tags.namespace | test("'"${namespaceTestRegex}"'")) | .name'))
  fi

  # If selected Key Vault list is empty, then ask user to select Key Vaults
  if [ ${#selectedKeyVaults[*]} -eq 0 ]; then
    # Prepare Key Vault list for user interaction
    echo -e "${DODGER_BLUE}\nKey Vault list:${NO_COLOR}"
    local num=1
    local finalVaults=()
    for keyVault in "${keyVaultNames[@]}"; do
      namespaceVault=$(echo "${allKeyVaults}" | jq -r '.[] | select(.name | test("'"${keyVault}"'")) | .tags.namespace // "No namespace"')

      color_subscription "\t${num}: ${keyVault} ( ${namespaceVault} ) (subscription: ${subscription} )"

      finalVaults+=("${keyVault}")
      num=$((num + 1))
    done
    echo -e "\tall: to all Key Vaults"
    echo -e "\tno: to skip"

    # Wait for user to select Key Vault(s)
    read -r -p "Which Key Vault(s)? Multiple choices are possible (Example: \"1 2 11\"): " -a inputs

    local end_early=false
    selectedKeyVaults=()
    for input in "${inputs[@]}"; do
      case ${input} in
        [0-9]*)
          local keyVaultIdx=$((input - 1))
          # Warn the user he selects a wrong index
          if [ "${keyVaultIdx}" -ge ${#finalVaults[@]} ]; then
            echo -e "\n${YELLOW}No Key Vault for index ${input}${NO_COLOR}"
          else
            # Add new element at the end of the array
            selectedKeyVaults[${#selectedKeyVaults[@]}]="${finalVaults[${keyVaultIdx}]}"
          fi
          ;;
        [aA][lL][lL] | [aA])
          echo -e "\nAll Key Vaults"
          selectedKeyVaults=("${finalVaults[@]}")
          end_early=true
          ;;
        *)
          echo -e "\nSkip..."
          exit 1
          ;;
      esac

      # Exit for loop
      if [ "${end_early}" == "true" ]; then
        break
      fi
    done
  fi

  if [ ${#selectedKeyVaults[*]} -eq 0 ]; then
    echo -e "\n${PINK}No Key Vault selected${NO_COLOR}"
  else
    echo -e "\n${PINK}Key Vaults selected: ${#selectedKeyVaults[*]} (${selectedKeyVaults[*]})${NO_COLOR}"
  fi
}

export -f info
export -f warn
export -f error

export -f check_cluster
export -f check_subscription
export -f confirm
export -f get_name_user
export -f is_connect_with_az_cli
export -f join_arr
export -f select_key_vault
