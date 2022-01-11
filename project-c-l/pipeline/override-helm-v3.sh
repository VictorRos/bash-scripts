#!/bin/bash

set -e # Exit on any error

# Environment variables
# AGENT_BUILD_DIRECTORY_PATH
# CONTEXT
# DOCKER_TAG
# HELM_DEVEL
# NAMESPACE_K8S
# REPOSITORY_DOCKER
# SERVICE_NAME

base_chart_path="${AGENT_BUILD_DIRECTORY_PATH}/charts/${SERVICE_NAME}"

helm_upgrade_options=(
  --debug
  -f "${base_chart_path}/values.yaml"
)

echo -e "\nUse --devel? ${HELM_DEVEL}\n"
if [ "${HELM_DEVEL}" = "true" ]; then
  echo -e "Add --devel option to helm command\n"
  helm_upgrade_options+=(
    --devel
  )
fi

# Include values.yaml from context and namespace
if [ -f "${base_chart_path}/${CONTEXT}/_common.yaml" ]; then
  helm_upgrade_options+=(
    -f "${base_chart_path}/${CONTEXT}/_common.yaml"
  )
fi
if [ -f "${base_chart_path}/${CONTEXT}/${NAMESPACE_K8S}.yaml" ]; then
  helm_upgrade_options+=(
    -f "${base_chart_path}/${CONTEXT}/${NAMESPACE_K8S}.yaml"
  )
fi

# Docker image name to use (overrides "image.repository")
TEMPLATE_IMAGE_REPOSITORY=${SERVICE_NAME}
if [ "${SERVICE_NAME}" = "frameworkfull-slow" ]; then
  TEMPLATE_IMAGE_REPOSITORY="frameworkfull"
fi

# Override tag & repository
override_repository=$(grep -q "repository:\s*$" "${base_chart_path}/values.yaml" && echo "true" || echo "false")
override_tag=$(grep -q "tag:\s*$" "${base_chart_path}/values.yaml" && echo "true" || echo "false")

if [ "${override_repository}" = "true" ] || [ "${override_tag}" = "true" ]; then
  echo -e "Override repository and tag\n"

  # Override repository
  helm_upgrade_options+=(--set image.repository="${REPOSITORY_DOCKER}/${TEMPLATE_IMAGE_REPOSITORY}")

  # Override tag
  helm_upgrade_options+=(--set image.tag="${DOCKER_TAG}")
fi

echo "HELM_UPGRADE_OPTIONS: ${helm_upgrade_options[*]}"

echo "##vso[task.setvariable variable=HELM_UPGRADE_OPTIONS]${helm_upgrade_options[*]}"
