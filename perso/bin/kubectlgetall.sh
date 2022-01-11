#!/usr/bin/env bash

if [ $# -ne 1 ]; then
  echo -e "Comment ça marche ?"
  echo -e "$0 <namespace>"
  exit 1
fi

RESOURCE_TYPES=$(kubectl api-resources --namespaced --verbs list --output name | paste -s -d ',' -)
kubectl get ${RESOURCE_TYPES} --show-kind -n $1
