#!/bin/bash

# Help to create kafka cluster and api key for Loop and Julie

set -e

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)
STORE_FOLDER="${SCRIPT_DIR}/../tmp/${SCRIPT_NAME}"

# Colors
blue="\033[0;34m"
green="\033[0;32m"
# red="\033[0;31m"
yellow="\033[0;33m"
nc="\033[0m" # No Color

# WARNING: Do not change order below!
# environments indexes correspond to clusters indexes (environments[0] is related to clusters[0], etc.)

# Specify the env/cluster. The list on the top are almost all dev env
environments=(
  # "env-307xo" # dev-flow-dev
  # "env-95n35" # dev-flow-test
  # "env-6zgr2" # dev-loop-compta-test
  # "env-zknq0" # dev-loop-compta-stable
  # "env-3d082" # dev-loop-compta-preprod
  # "env-7dzyp" # dev-loop-compta-tnr
  # "env-g52qn" # dev-loop-deployment-test
  # "env-p2nw5" # dev-loop-modelisation
  # "env-vk97n" # dev-loop-testenv001
  # "env-9dok5" # dev-loop-testenv002
  # "env-jr25w" # dev-loop-testenv003
  # "env-v5mnn" # dev-loop-test-fw
  # "env-r6grk" # dev-loop-test-gi
  # "env-8d717" # dev-loop-pia-test
  # "env-89kr7" # dev-loop-iso-prod
  # "env-dgrk1" # integration
  # "env-6o0d8" # production
)
clusters=(
  # "lkc-n3ry6" # dev-flow-dev
  # "lkc-5d7v2" # dev-flow-test
  # "lkc-p1wrm" # dev-loop-compta-test
  # "lkc-x8wnq" # dev-loop-compta-stable
  # "lkc-2n6g1" # dev-loop-compta-preprod
  # "lkc-8p6rq" # dev-loop-compta-tnr
  # "lkc-nq3gd" # dev-loop-deployment-test
  # "lkc-qoyj7" # dev-loop-modelisation
  # "lkc-7g982" # dev-loop-testenv001
  # "lkc-pp1vy" # dev-loop-testenv002
  # "lkc-x8zgq" # dev-loop-testenv003
  # "lkc-k1q0m" # dev-loop-test-fw
  # "lkc-rxo30" # dev-loop-test-gi
  # "lkc-02715" # dev-loop-pia-test
  # "lkc-00dx5" # dev-loop-iso-prod
  # "lkc-k622p" # integration
  # "lkc-d5077" # production
)

# WARNING: Do not change order below!
# users and descriptions are related by indexes (users[0] is related to clusterDescriptions[0] and schemaRegistryDescriptions[0], etc.)

# User service account
users=(
  # "pia_bk"
  # "julie-ops"
  # "flow-dev"
  # "loop-dev"
)
# Description for cluster API Key
clusterDescriptions=(
  # "PIA BK"
  # "Julie Ops ADO"
  # "Flow DEV App"
  # "Loop DEV App"
)
# Description for schema registry API Key
schemaRegistryDescriptions=(
  # "PIA BK"
  # "Julie Ops ADO"
  # "Flow DEV App"
  # "Loop DEV App"
)

##############################################################
#####                    Functions                       #####
##############################################################

create_cluster_api_key() {
  user=$1
  userId=$2
  clusterId=$3
  description=$4
  secretDirectory=$5

  echo -e "Create cluster API Key for ${user} (${userId})"
  clusterApiKey=$(confluent api-key create --resource "${clusterId}" --description "${description}" --service-account "${userId}" --output json)

  prefixSecret=""
  if [ "${user}" == "julie-ops" ]; then
    prefixSecret="julie-"
  fi

  echo -e "${green}Retrieve ${prefixSecret}kafka-cluster-api-key in ${secretDirectory}${nc}"
  kafkaClusterApiKey=$(echo "${clusterApiKey}" | jq -r '.key')
  echo -n "${kafkaClusterApiKey}" > "${secretDirectory}/${prefixSecret}kafka-cluster-api-key"

  echo -e "${green}Retrieve ${prefixSecret}kafka-cluster-api-secret in ${secretDirectory}${nc}"
  kafkaClusterApiSecret=$(echo "${clusterApiKey}" | jq -r '.secret')
  echo -n "${kafkaClusterApiSecret}" > "${secretDirectory}/${prefixSecret}kafka-cluster-api-secret"
}

create_schema_registry_api_key() {
  user=$1
  userId=$2
  schemaRegistryId=$3
  description=$4
  secretDirectory=$5

  echo -e "Create schema registry API Key for ${user} (${userId})"
  schemaRegistryApiKey=$(confluent api-key create --resource "${schemaRegistryId}" --description "${description}" --service-account "${userId}" --output json)

  prefixSecret=""
  if [ "${user}" == "julie-ops" ]; then
    prefixSecret="julie-"
  fi
  echo -e "${green}Retrieve ${prefixSecret}kafka-schema-registry-api-key in ${secretDirectory}${nc}"
  kafkaSchemaRegistryApiKey=$(echo "${schemaRegistryApiKey}" | jq -r '.key')
  echo -n "${kafkaSchemaRegistryApiKey}" > "${secretDirectory}/${prefixSecret}kafka-schema-registry-api-key"

  echo -e "${green}Retrieve ${prefixSecret}kafka-schema-registry-api-secret in ${secretDirectory}${nc}"
  kafkaSchemaRegistryApiSecret=$(echo "${schemaRegistryApiKey}" | jq -r '.secret')
  echo -n "${kafkaSchemaRegistryApiSecret}" > "${secretDirectory}/${prefixSecret}kafka-schema-registry-api-secret"
}

create_acls_topic() {
  user=$1
  userId=$2

  echo -e "Create Topics ACLs for ${user} (${userId})"
  if [ "${user}" == "julie-ops" ]; then
    confluent kafka acl create --allow --service-account "${userId}" --operation "alter" --topic "*"
    confluent kafka acl create --allow --service-account "${userId}" --operation "alter-configs" --topic "*"
    confluent kafka acl create --allow --service-account "${userId}" --operation "create" --topic "*"
  fi
  confluent kafka acl create --allow --service-account "${userId}" --operation "read" --topic "*"
  confluent kafka acl create --allow --service-account "${userId}" --operation "write" --topic "*"

  # PIA
  # confluent kafka acl create --allow --service-account "${userId}" --operation "read" --topic "fr.cegid.loop.iban" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "write" --topic "fr.cegid.loop.iban" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "read" --topic "fr.cegid.loop.accountId" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "write" --topic "fr.cegid.loop.accountId" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "read" --topic "fr.cegid.loop.aspsp" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "write" --topic "fr.cegid.loop.aspsp" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "read" --topic "queuing.cpa" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "write" --topic "queuing.cpa" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "read" --topic "fr.cegid.loop.bank" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "write" --topic "fr.cegid.loop.bank" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "read" --topic "queuing.pia" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "write" --topic "queuing.pia" --prefix
}

create_acls_consumer_group() {
  user=$1
  userId=$2

  echo -e "Create Consumer Group ACLs for ${user} (${userId})"
  confluent kafka acl create --allow --service-account "${userId}" --operation "read" --consumer-group "*"
  confluent kafka acl create --allow --service-account "${userId}" --operation "describe" --consumer-group "*"

  # PIA
  # confluent kafka acl create --allow --service-account "${userId}" --operation "read" --consumer-group "pia-accounting" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "describe" --consumer-group "pia-accounting" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "read" --consumer-group "fr.cegid.loop.bank" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "describe" --consumer-group "fr.cegid.loop.bank" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "read" --consumer-group "fr.cegid.loop.transaction" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "describe" --consumer-group "fr.cegid.loop.transaction" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "read" --consumer-group "fr.cegid.loop.statement" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "describe" --consumer-group "fr.cegid.loop.statement" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "read" --consumer-group "fr.cegid.loop.pia" --prefix
  # confluent kafka acl create --allow --service-account "${userId}" --operation "describe" --consumer-group "fr.cegid.loop.pia" --prefix
}

##############################################################
#####                      Main                          #####
##############################################################

# Create tmp directory if it not exists
if [ ! -d "${STORE_FOLDER}" ]; then
  echo -e "Create ${STORE_FOLDER} directory\n"
  mkdir -p "${STORE_FOLDER}"
fi

# For each tuples of environment/cluster
for ((i = 0; i < ${#clusters[@]}; i++)); do
  clusterId=${clusters[$i]}
  environmentId=${environments[$i]}
  secretDirectory="${STORE_FOLDER}/${environmentId}"

  echo -e "${blue}**********************************${nc}"
  echo -e "${blue}***** Environment: ${environmentId} *****${nc}"
  echo -e "${blue}***** Cluster:     ${clusterId} *****${nc}"
  echo -e "${blue}**********************************${nc}\n"

  # Create secretDirectory directory if it not exists
  if [ ! -d "${secretDirectory}" ]; then
    echo -e "Create ${secretDirectory} directory\n"
    mkdir -p "${secretDirectory}"
  fi

  confluent environment use "${environmentId}"
  confluent kafka cluster use "${clusterId}"

  echo -e "\n${green}Retrieve kafka-brokers in ${secretDirectory}${nc}"
  brokersURL=$(confluent kafka cluster describe "${clusterId}" --output json | jq -r '.endpoint')
  echo -n "${brokersURL//SASL_SSL:\/\//}" > "${secretDirectory}/kafka-brokers"

  echo -e "\nGet schema registry infos"
  schemaRegistryInfo=$(confluent schema-registry cluster enable --cloud azure --geo eu --environment "${environmentId}" --output json)
  schemaRegistryId=$(echo "${schemaRegistryInfo}" | jq -r '.id')

  echo -e "${green}Retrieve kafka-schema-registry-url in ${secretDirectory}${nc}"
  schemaRegistryBrokers=$(echo "${schemaRegistryInfo}" | jq -r '.endpoint_url')
  echo -n "${schemaRegistryBrokers}" > "${secretDirectory}/kafka-schema-registry-url"

  # For each users
  for ((j = 0; j < ${#users[@]}; j++)); do
    user=${users[$j]}
    clusterDescription=${clusterDescriptions[$j]}
    schemaRegistryDescription=${schemaRegistryDescriptions[$j]}

    echo -e "\nGet service account ${user}"
    userId=$(confluent iam service-account list -o json | jq -r ".[] | select(.name | test(\"${user}\")) | .id")

    # Continue with next user if no user has been found
    if [ "${userId}" == "" ]; then
      echo -e "${yellow}User not found: ${user}${nc}"
      continue
    fi

    create_cluster_api_key "${user}" "${userId}" "${clusterId}" "${clusterDescription}" "${secretDirectory}"
    create_schema_registry_api_key "${user}" "${userId}" "${schemaRegistryId}" "${schemaRegistryDescription}" "${secretDirectory}"
    create_acls_topic "${user}" "${userId}"
    create_acls_consumer_group "${user}" "${userId}"
  done
done
