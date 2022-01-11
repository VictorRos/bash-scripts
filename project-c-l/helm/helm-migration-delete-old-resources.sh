#!/bin/bash

source "$(dirname $0)/helm-library.sh"

if [ "$1" = "" ]; then
    error "Namespace is mandatory."
    exit 1
elif [ "$2" = "" ]; then
    error "Service name is mandatory."
    exit 1
fi

namespace=$1
service_name=$2

kubectl delete configmap "${service_name}" -n "${namespace}" --ignore-not-found
kubectl delete cronjob "${service_name}" -n "${namespace}" --ignore-not-found
kubectl delete deployment "${service_name}" -n "${namespace}" --ignore-not-found
kubectl delete hpa "${service_name}" -n "${namespace}" --ignore-not-found
kubectl delete ingress "${service_name}" -n "${namespace}" --ignore-not-found
kubectl delete job "${service_name}" -n "${namespace}" --ignore-not-found
kubectl delete pdb "${service_name}" -n "${namespace}" --ignore-not-found
kubectl delete service "${service_name}" -n "${namespace}" --ignore-not-found
