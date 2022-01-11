#!/bin/bash

set -e # Exit on any error

# Parameters
NAMESPACE_K8S=$1
SUBSCRIPTION=$2
HOSTNAME=$3
API_HOSTNAME=$4
WEB_HOSTNAME=$5

echo -e "Number of arguments: $#"

echo -e "NAMESPACE_K8S: ${NAMESPACE_K8S}"
echo -e "SUBSCRIPTION: ${SUBSCRIPTION}"
echo -e "HOSTNAME: ${HOSTNAME}"
echo -e "API_HOSTNAME: ${API_HOSTNAME}"
echo -e "WEB_HOSTNAME: ${WEB_HOSTNAME}"

COLOR_BLUE="\x1b[34m"
COLOR_YELLOW="\x1b[33m"
NO_COLOR="\x1b[0m"

info() {
  echo -e "\n${COLOR_BLUE}$1${NO_COLOR}"
}

title() {
  echo -e "\n${COLOR_YELLOW}$1${NO_COLOR}"
  echo -e "${COLOR_YELLOW}- - - - - - - - - - - - - - - - - - - - - - - - - - - - -${NO_COLOR}"
}

title "1) Download secrets"

info "Extension azure-devops is not native, it must be installed"
az extension add --name azure-devops

info "Create a tmp directory to store user-config templates"
rm -rf tmp
mkdir tmp
mkdir tmp/website

keyVault=""
annotations=""
if [ "${SUBSCRIPTION}" == "SAAS-8307-INTE" ]; then
  keyVault=SEC830700KVTI01
elif [ "${SUBSCRIPTION}" == "SAAS-8307-PROD" ]; then
  keyVault=SEC830700KVT001
else
  info "Retrieve Key Vault list"
  keyVaultList=$(az keyvault list)

  echo -e "Key Vault list:\n${keyVaultList}"

  info "Download user-config-template secret"
  info "az keyvault secret download --vault-name SEC830700KVTD16-COMMUN --name user-config-template -f tmp/user-config-template.json"
  az keyvault secret download --vault-name SEC830700KVTD16-COMMUN --name user-config-template -f tmp/user-config-template.json

  info "Generate uri-user-config-template annotation"
  uri=$(az keyvault secret show --vault-name SEC830700KVTD16-COMMUN --name user-config-template --query=id)
  annotations="${annotations}, \"uri-user-config-template\": ${uri}"

  info "Download user-config-website secret"
  info "az keyvault secret download --vault-name SEC830700KVTD16-COMMUN --name user-config-website -f tmp/user-config-website.json"
  az keyvault secret download --vault-name SEC830700KVTD16-COMMUN --name user-config-website -f tmp/user-config-website.json

  info "Generate uri-user-config-website annotation"
  uri=$(az keyvault secret show --vault-name SEC830700KVTD16-COMMUN --name user-config-website --query=id)
  annotationsWebsite="\"uri-user-config-website\": ${uri}"

  info "Get Key Vault for K8s namespace ${NAMESPACE_K8S}"
  keyVault=$(echo "${keyVaultList}" | jq -r '.[] | select(.tags.namespace != null) | select(.tags.namespace | test("'"${NAMESPACE_K8S}"'")) | .name')
fi

info "Key Vault selected: ${keyVault}"

info "Get user-config* secrets from Key Vault ${keyVault}"
secretInfos=$(az keyvault secret list --vault-name "${keyVault}")
secretNames=($(echo "${secretInfos}" | jq -r '.[] | select(.name|test("^user-config.")) | .name'))
info "Secrets found:\n${secretNames[*]}"

for secretName in "${secretNames[@]}"; do
  info "Download ${secretName} secret"
  info "az keyvault secret download --vault-name \"${keyVault}\" --name \"${secretName}\" -f \"tmp/${secretName}.json\""
  az keyvault secret download --vault-name "${keyVault}" --name "${secretName}" -f "tmp/${secretName}.json"

  info "Generate uri-${secretName} annotation"
  uri=$(az keyvault secret show --vault-name "${keyVault}" --name "${secretName}" --query=id)
  if [ "${secretName}" != "user-config-website" ]; then
    annotations="${annotations}, \"uri-${secretName}\": ${uri}"
  else
    annotationsWebsite="\"uri-${secretName}\": ${uri}"
  fi
done

title "2) Create user-config-${NAMESPACE_K8S}.json"

mv tmp/user-config-template.json tmp/config-template.json
mv tmp/user-config-website.json tmp/website/user-config-website.json

ls -alR tmp/
info "Merge user-config-template.json with all user-config-*.json to user-config-${NAMESPACE_K8S}.json"
jq -S -s 'add' tmp/config-template.json tmp/user-config-*.json > "user-config-${NAMESPACE_K8S}.json"
info "Merge user-config-template.json with all user-config-*.json and user-config-website to user-config-${NAMESPACE_K8S}-website.json"
jq -S -s 'add' tmp/config-template.json tmp/user-config-*.json tmp/website/user-config-website.json > "user-config-${NAMESPACE_K8S}-website.json"

# Handle cases where WEB_HOSTNAME has no value, we use HOSTNAME value instead.
if [ "${WEB_HOSTNAME}" == "" ]; then
  WEB_HOSTNAME=${HOSTNAME}
fi

info "Replace __HOSTNAME__ with ${HOSTNAME} in user-config-${NAMESPACE_K8S}.json"
sed -i "s/__HOSTNAME__/${HOSTNAME}/g" "user-config-${NAMESPACE_K8S}.json"
info "Replace __HOSTNAME__ with ${WEB_HOSTNAME} in user-config-${NAMESPACE_K8S}-website.json"
sed -i "s/__HOSTNAME__/${WEB_HOSTNAME}/g" "user-config-${NAMESPACE_K8S}-website.json"

# Note: If "apiHostname" parameter is different from "hostname" parameter and its value is not an empty value ("")
# then we replace __API_HOSTNAME__ with "apiHostname", otherwise we replace with "hostname"
if [ "${API_HOSTNAME}" != "${HOSTNAME}" ] \
  && [ "${API_HOSTNAME}" != "" ]; then
  info "Replace __API_HOSTNAME__ with ${API_HOSTNAME}"
  sed -i "s/__API_HOSTNAME__/${API_HOSTNAME}/g" "user-config-${NAMESPACE_K8S}.json"
  sed -i "s/__API_HOSTNAME__/${API_HOSTNAME}/g" "user-config-${NAMESPACE_K8S}-website.json"
else
  info "Replace __API_HOSTNAME__ with ${HOSTNAME} in user-config-${NAMESPACE_K8S}.json"
  sed -i "s/__API_HOSTNAME__/${HOSTNAME}/g" "user-config-${NAMESPACE_K8S}.json"
  info "Replace __API_HOSTNAME__ with ${WEB_HOSTNAME} in user-config-${NAMESPACE_K8S}-website.json"
  sed -i "s/__API_HOSTNAME__/${WEB_HOSTNAME}/g" "user-config-${NAMESPACE_K8S}-website.json"
fi

echo "##vso[task.setvariable variable=ANNOTATIONS;isOutput=true]${annotations}"

if [ "${annotationsWebsite}" != "" ]; then
  annotationsWebsite="${annotations}, ${annotationsWebsite}"
else
  annotationsWebsite="${annotations}"
fi
echo "##vso[task.setvariable variable=ANNOTATIONS_WEBSITE;isOutput=true]${annotationsWebsite}"
