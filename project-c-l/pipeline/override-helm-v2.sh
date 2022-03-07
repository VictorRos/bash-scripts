#!/bin/bash

set -e # Exit on any error

# Environment variables
# AGENT_BUILD_DIRECTORY_PATH
# CONTEXT
# DOCKER_TAG
# HOSTNAME
# IS_CRONJOB
# IS_INTEGRATION
# IS_NEW_CLUSTER
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

echo -e "IS_CRONJOB: ${IS_CRONJOB}"
echo -e "IS_INTEGRATION: ${IS_INTEGRATION}"
echo -e "IS_NEW_CLUSTER: ${IS_NEW_CLUSTER}"
echo -e "IS_TEST: ${IS_TEST}\n"

# Override context
echo "
  template:
    context: ${CONTEXT}" > "${AGENT_BUILD_DIRECTORY_PATH}/helm-overrides.yaml"

# Override image
echo "
    image:
      tag: ${DOCKER_TAG}
      repository: ${REPOSITORY_DOCKER}/${SERVICE_NAME}" >> "${AGENT_BUILD_DIRECTORY_PATH}/helm-overrides.yaml"

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
      maxReplicas: 2
      minBudgetReplicas: 0" >> "${AGENT_BUILD_DIRECTORY_PATH}/helm-overrides.yaml"
elif [ "${IS_INTEGRATION}" = "true" ]; then
  echo "
    autoscaling:
      replicaCount: 1
      minReplicas: 1
      maxReplicas: 3
      minBudgetReplicas: 0" >> "${AGENT_BUILD_DIRECTORY_PATH}/helm-overrides.yaml"
fi

# Override ingress
if [ "${IS_TEST}" = "true" ] || [ "${IS_INTEGRATION}" = "true" ]; then
  echo "
    ingress:
      hosts:
        - hostname: ${HOSTNAME}
          path: /([^/]+)/service/${SERVICE_NAME}/(.*)
      tls:
        - hosts:
            - ${HOSTNAME}" >> "${AGENT_BUILD_DIRECTORY_PATH}/helm-overrides.yaml"
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
