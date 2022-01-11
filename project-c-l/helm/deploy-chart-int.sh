#!/usr/bin/env bash

set -e # Exit on any error

# Prérequis : Se connecter à Azure et au cluster d'intégration

if [ $# -ne 8 ]; then
  echo -e "How it works?"
  echo -e "$0 <HELM_LOOP_REPO> <HELM_REPO_LOGIN> <HELM_REPO_PWD> <SERVICE_NAME> <REPOSITORY_DOCKER> <TAG> <CHART_VERSION> <NAMESPACE>"
  echo -e "\nDeploy a specific Chart Helm version for a service."
  echo -e "\n<HELM_LOOP_REPO> : Helm Loop repo url"
  echo -e "<HELM_REPO_LOGIN> : Helm Loop repo login"
  echo -e "<HELM_REPO_PWD> : Helm Loop repo password"
  echo -e "<SERVICE_NAME> : Service name"
  echo -e "<REPOSITORY_DOCKER> : Docker repository"
  echo -e "<TAG> : Docker image tag"
  echo -e "<CHART_VERSION> : Chart Helm version"
  echo -e "<NAMESPACE> : Namespace to deploy"
  exit 1
fi

# Variables Helm (à récupérer depuis le Key Vault Azure SEC830700KVTD01)
HELM_LOOP_REPO=$1  # Secret compta-helm-repo-url
HELM_REPO_LOGIN=$2 # Secret compta-helm-repo-login
HELM_REPO_PWD=$3   # Secret compta-helm-repo-pw

# Variables Service
# Nom du service (Ex: cfonb-retention)
SERVICE_NAME=$4
# Emplacement du service (Ex: cegid-loop-docker-staging.jfrog.io/arpege-web/3.7.2_rc2)
REPOSITORY_DOCKER=$5
# Tag composé de la version de Loop et du numéro de build (Ex: 4.17.1-20210118.1)
TAG=$6
# Version du Chart Helm à déployer (Ex: 0.1.9)
CHART_VERSION=$7
# Namespace où déployer (Ex: current)
NAMESPACE=$8

# Récupération du repo Loop
helm repo add loop ${HELM_LOOP_REPO} \
  --username ${HELM_REPO_LOGIN} \
  --password ${HELM_REPO_PWD} \
  --debug

# Mise à jour du repo
helm repo update

# Récupération de la version précise du Chart Helm du service
helm fetch loop/${SERVICE_NAME} \
  --version ${CHART_VERSION} \
  --untar \
  --destination /tmp/loop-charts

# Surcharge Helm
helm template ${SERVICE_NAME}-${NAMESPACE} \
  /tmp/loop-charts/${SERVICE_NAME} \
  --namespace ${NAMESPACE} \
  --set template.image.tag=${TAG} \
  --set template.image.repository=${REPOSITORY_DOCKER}/${SERVICE_NAME} \
  --set template.autoscaling.minBudgetReplicas=0 \
  --set template.ingress.hosts={} \
  --set template.ingress.hosts[0].hostname=loop-int.loopsoftware.fr \
  --set template.ingress.hosts[0].path=/\(.*\)/service/${SERVICE_NAME}/\(.*\) \
  --set template.ingress.hosts[0].serviceName=${SERVICE_NAME} \
  --set template.ingress.hosts[0].servicePort=http \
  --set template.ingress.tls[0].hosts={loop-int.loopsoftware.fr} \
  --set template.ingress.tls[0].secretName=wildcard-loop > /tmp/loop-charts/${SERVICE_NAME}-int.manifest

# Appliquer le manifest
kubectl apply \
  -f /tmp/loop-charts/${SERVICE_NAME}-int.manifest \
  --namespace ${NAMESPACE}
