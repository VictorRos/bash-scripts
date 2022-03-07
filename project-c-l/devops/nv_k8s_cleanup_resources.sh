#!/bin/bash

# Delete all ressource of one service in one namespace

set -e

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

source "${SCRIPT_DIR}/library/nv_library.sh"

# Namespace
if [ "$1" = "" ]; then
  error "Namespace is mandatory."
  exit 1
else
  namespace=$1
fi
# Services
if [ "$2" != "" ]; then
  service_list=("$2")
else
  warn "Service name is not defined. Remove all services.\n"
  # Get all services
  service_list=($(kubectl get cj,deploy,hpa,pdb,sj,so,svc -n "${namespace}" -o name | sed -E "s|[^/]+/||g" | sort -u))
fi

# Show subscription and cluster
check_subscription
check_cluster

# Ask before doing a terrible mistake!
echo ""
confirm "Are you sure you want to remove all K8s resources for ${#service_list[@]} service(s) in namespace ${namespace}? [y/N]"

k8s_resources=(
  "configmaps"
  "cronjobs"
  "deployments"
  "horizontalpodautoscalers"
  "ingresses"
  "jobs"
  "poddisruptionbudgets"
  "secrets"
  "scaledjobs"
  "scaledobjects"
  "services"
)

for k8s_resource in "${k8s_resources[@]}"; do
  info "\n***** Remove ${k8s_resource} *****"
  for resource_to_delete in "${service_list[@]}"; do
    # Remove only user-config in secrets
    if [ "${k8s_resource}" = "secrets" ]; then
      resource_to_delete="user-config-${resource_to_delete}"
    fi
    kubectl delete "${k8s_resource}" "${resource_to_delete}" -n "${namespace}" --ignore-not-found
  done
done

info "\nFinished!"
