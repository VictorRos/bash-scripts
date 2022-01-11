#!/bin/bash

# Delete all ressource of one service in one namespace

set -e

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

source "${SCRIPT_DIR}/library/nv_library.sh"

if [ "$1" = "" ]; then
  error "Namespace is mandatory."
  exit 1
elif [ "$2" = "" ]; then
  error "Service name is mandatory."
  exit 1
fi

namespace=$1
service_name=$2

# Show subscription and cluster
check_subscription
check_cluster

# Ask before doing a terrible mistake!
confirm "Are your sure you want to remove all K8s resources for ${service_name} in namespace ${namespace}? [y/N]"

k8s_resources=(
  "configmap"
  "cronjob"
  "deployment"
  "hpa"
  "ingress"
  "job"
  "pdb"
  "service"
)

for k8s_resource in "${k8s_resources[@]}"; do
  kubectl delete "${k8s_resource}" "${service_name}" -n "${namespace}" --ignore-not-found
done
