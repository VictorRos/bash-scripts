#!/bin/bash

set -e

SERVICE_NAME=ydbdatadirect
HOSTNAME_SOURCE=loop
HOSTNAME_TARGET=office
NAMESPACE_SOURCE=loop
NAMESPACE_TARGET=office

echo "Get user-config secret and remove some metadata + update namespace"
user_config_secret=$(kubectl get secret user-config-${SERVICE_NAME} -n ${NAMESPACE_SOURCE} -o json \
  | jq 'del(.metadata.managedFields, .metadata.uid, .metadata.creationTimestamp, .metadata.resourceVersion)' \
  | jq '.metadata.annotations |= {}' \
  | jq ".metadata.namespace |= sub(\"${NAMESPACE_SOURCE}\"; \"${NAMESPACE_TARGET}\")")

echo "Update hostname in user-config content"
user_config_new_content=$(echo "${user_config_secret}" \
  | jq -r '.data["user-config.json"]' \
  | base64 -d \
  | sed s/${HOSTNAME_SOURCE}\.loopsoftware\.fr/${HOSTNAME_TARGET}\.loopsoftware\.fr/ \
  | sed s/${HOSTNAME_SOURCE}-int\.loopsoftware\.fr/${HOSTNAME_TARGET}-int\.loopsoftware\.fr/ \
  | base64)

echo "Create/Update user-config"
echo "${user_config_secret}" | jq ".data[\"user-config.json\"]=\"${user_config_new_content}\"" | kubectl apply -f -
