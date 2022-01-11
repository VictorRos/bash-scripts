#!/bin/bash

set -e # Exit on any error

# Environment variables
# AGENT_BUILD_DIRECTORY_PATH
# CONTEXT
# DOCKER_TAG
# HOSTNAME
# IS_BETA
# IS_CRONJOB
# IS_INTEGRATION
# IS_NEW_CLUSTER
# IS_PRODUCTION
# IS_TEST
# REPOSITORY_DOCKER
# RESOURCE_CPU_LIMITS
# RESOURCE_CPU_REQUESTS
# RESOURCE_MEMORY_LIMITS
# RESOURCE_MEMORY_REQUESTS
# SERVICE_NAME
# SYSTEM_DEBUG

# Only in debug mode
if [ "${SYSTEM_DEBUG}" = "true" ]; then
  echo -e "\ncharts/${SERVICE_NAME}/Chart.yaml\n"
  cat "charts/${SERVICE_NAME}/Chart.yaml"

  echo -e "\ncharts/${SERVICE_NAME}/values.yaml\n"
  cat "charts/${SERVICE_NAME}/values.yaml"
fi

echo -e "IS_BETA: ${IS_BETA}"
echo -e "IS_CRONJOB: ${IS_CRONJOB}"
echo -e "IS_INTEGRATION: ${IS_INTEGRATION}"
echo -e "IS_NEW_CLUSTER: ${IS_NEW_CLUSTER}"
echo -e "IS_PRODUCTION: ${IS_PRODUCTION}"
echo -e "IS_TEST: ${IS_TEST}\n"

# Service fullname
SERVICE_FULLNAME=${SERVICE_NAME}
# Start TODO: Delete this part when we can stop renaming services
if [ "${SERVICE_NAME}" = "frameworkfull" ]; then
  SERVICE_FULLNAME=fw-loop
elif [ "${SERVICE_NAME}" = "serverfunction" ]; then
  SERVICE_FULLNAME=sf-loop
fi
# End TODO

# Override context
echo "
  template:
    context: ${CONTEXT}
    fullname: ${SERVICE_FULLNAME}" > "${AGENT_BUILD_DIRECTORY_PATH}/helm-overrides.yaml"

# Docker image name to use (overrides "template.image.repository")
TEMPLATE_IMAGE_REPOSITORY=${SERVICE_NAME}
if [ "${SERVICE_NAME}" = "frameworkfull-slow" ]; then
  TEMPLATE_IMAGE_REPOSITORY="frameworkfull"
fi

# Override image
echo "
    image:
      tag: ${DOCKER_TAG}
      repository: ${REPOSITORY_DOCKER}/${TEMPLATE_IMAGE_REPOSITORY}" >> "${AGENT_BUILD_DIRECTORY_PATH}/helm-overrides.yaml"

# Override spec
if [ "${IS_CRONJOB}" = "true" ] && [ "${IS_TEST}" = "true" ]; then
  echo "
    spec:
      schedule: '*/10 * * * *'" >> "${AGENT_BUILD_DIRECTORY_PATH}/helm-overrides.yaml"
fi

# Override replicas
if [ "${IS_TEST}" = "true" ]; then
  echo "
    autoscaling:
      replicaCount: 1
      minReplicas: 1
      maxReplicas: 1
      minBudgetReplicas: 0" >> "${AGENT_BUILD_DIRECTORY_PATH}/helm-overrides.yaml"
elif [ "${IS_INTEGRATION}" = "true" ] || { [ "${IS_PRODUCTION}" = "true" ] && [ "${IS_BETA}" = "true" ]; }; then
  echo "
    autoscaling:
      replicaCount: 1
      minReplicas: 1
      maxReplicas: 2
      minBudgetReplicas: 0" >> "${AGENT_BUILD_DIRECTORY_PATH}/helm-overrides.yaml"
fi

# Override ingress
if [ "${IS_TEST}" = "true" ] || [ "${IS_INTEGRATION}" = "true" ] || { [ "${IS_PRODUCTION}" = "true" ] && [ "${IS_BETA}" = "true" ]; }; then
  if [ "${SERVICE_NAME}" = "frameworkfull-slow" ]; then
    echo "
    ingress:
      hosts:
        - hostname: ${HOSTNAME}
          path: /YPND
        - hostname: ${HOSTNAME}
          path: /shared
        - hostname: ${HOSTNAME}
          path: /ws
        - hostname: ${HOSTNAME}
          path: /YPN/.*/.*/fetch
        - hostname: ${HOSTNAME}
          path: /YPN/.*/.*/AzureFileStorageEx/(download|upload)
        # Les endpoints de cleacore gérés par frameworkfull-slow sont temporaires.
        # Les équipes de PIA doivent faire le nécessaire pour que cleacore gère ses propres endpoints.
        - hostname: ${HOSTNAME}
          path: /YPN/.*/.*/cleacore/(generateCompanyFeedback|sendFeedback)
        - hostname: ${HOSTNAME}
          path: /YPN/.*/.*/cleaspwatcher/checkWebHookAndWatch
      tls:
        - hosts:
          - ${HOSTNAME}" >> "${AGENT_BUILD_DIRECTORY_PATH}/helm-overrides.yaml"
  else
    INGRESS_PATH="/([^/]+)/service/${SERVICE_NAME}/(.*)"
    if [ "${SERVICE_NAME}" = "frameworkfull" ]; then
      INGRESS_PATH="/"
    elif [ "${SERVICE_NAME}" = "serverfunction" ]; then
      INGRESS_PATH="/([^/]+)/service/sf-loop/(.*)"
    fi

    echo "
    ingress:
      hosts:
        - hostname: ${HOSTNAME}
          path: ${INGRESS_PATH}
      tls:
        - hosts:
          - ${HOSTNAME}" >> "${AGENT_BUILD_DIRECTORY_PATH}/helm-overrides.yaml"
  fi
fi

# Override resources
if [ "${IS_TEST}" = "true" ]; then
  echo "
    resources:
      limits:
        cpu: ${RESOURCE_CPU_LIMITS}
        memory: ${RESOURCE_MEMORY_LIMITS}
      requests:
        cpu: ${RESOURCE_CPU_REQUESTS}
        memory: ${RESOURCE_MEMORY_REQUESTS}" >> "${AGENT_BUILD_DIRECTORY_PATH}/helm-overrides.yaml"
fi

# Override tolerations
if [ "${IS_NEW_CLUSTER}" = "false" ]; then
  echo "
    tolerations: []" >> "${AGENT_BUILD_DIRECTORY_PATH}/helm-overrides.yaml"
fi

# Override affinity
if [ "${IS_NEW_CLUSTER}" = "false" ]; then
  echo "
    affinity:
  " >> "${AGENT_BUILD_DIRECTORY_PATH}/helm-overrides.yaml"
fi

# Remove 2 spaces ahead of each lines
# (all echo commands add 2 spaces because they are in if conditions)
sed -i "s/^  //" "${AGENT_BUILD_DIRECTORY_PATH}/helm-overrides.yaml"

# Display all overrides
cat "${AGENT_BUILD_DIRECTORY_PATH}/helm-overrides.yaml"
