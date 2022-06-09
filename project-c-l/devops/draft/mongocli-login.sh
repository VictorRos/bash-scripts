#!/bin/bash

# shellcheck disable=SC2034

password="####"

services_clea=(
  "cleaaccountpredictor"
  "cleacore"
  "cleaextractor"
  "cleagenerator"
  "cleaspwatcher"
)

services_pia=(
  "pia-account-class-predictor-train"
  "pia-account-class-preprocess"
  "pia-accountclassifier-predict"
  "pia-api"
  "pia-archiver"
  "pia-documentclassifier-predict"
  "pia-gql"
  "pia-languageclassifier-predict"
  "pia-pdf-splitter-predict"
  "pia-qualityextraction-predict"
  "pia-queryhandler"
  "pia-supplierclass-predict"
  "pia-ui"
)

services_framework=(
  "events-service"
  "fw-loop"
  "publicapi"
  "sf-loop"
  "ydbdata"
  "ydbdatadirect"
  "ydbutils"
)

services_gi=(
  "bluewayextractor"
  "customersubscription"
  "editionmanager"
  "gimanager"
  "loopkafkamanager"
  "office365manager"
  "loophubcollaboratif"
  "loophubcollaboratifdirect"
)

services_cae=(
  "cae-ecriture"
  "cae-external-accounting"
  "cae-initialisation"
  "loopcaemanager"
  "rightmanager"
  "securitymanager"
  "signaturemanager"
  "sirenmanager"
  "testmanager"
  "reportmanager"
)

services_paie=(
  "calendrier"
  "bulletin"
  "bulletingenerator"
  "elementpaie"
  "paie-engine"
  "paie-teams"
)

services_releves=(
  "jdcreleveservice"
  "relevejdcscheduler"
  "releverefjdcscheduler"
  "releverefsftpscheduler"
  "relevesftpscheduler"
  "sftpreleveservice"
)

services_imports=(
  "api-import-ecritures"
  "import-ecritures"
  "importcontratoc"
  "importrdd"
  "importrelevedsp2"
  "publicrdd"
)

services_other=(
  "alertmanager"
  "bankinscheduler"
  "comptesedi"
  "currencyimporter"
  "dossierpaie"
  "dpserver"
  "dsn"
  "dsp2bankindexer"
  "ecriturestresoservice"
  "envoisedi"
  "expensyawatcher"
  "individu"
  "lexisnexis"
  "lexisnexisconnector"
  "loop-website"
  "missioncac"
  "onenoterevision"
  "parefeuservice"
  "referentielmanager"
  "retoursedi"
  "tillerscheduler"
  "tresoalertnotifier"
  "workflowproxy"
  "workflowscheduler"
)

names=(
  "clea"
  "pia"
  "framework"
  "gi"
  "cae"
  "paie"
  "releves"
  "imports"
  "other"
)

prefix="loop-"
namespace="compta-test"

# scope="DEV-LOOP"
# projectId="5b7599404e65816be9d64e77"

echo -e "Nb Groups: ${#names[@]}"
pods=$(kubectl get pods -n ${namespace} -o json)

for name in "${names[@]}"; do
  serviceGroupName="services_${name}"
  services=()
  # Eval expression to get array for serviceGroupName
  eval services='(${'"${serviceGroupName}"'})'

  echo -e "\nService group: ${name}, number of services: ${#services[@]}"

  username="${prefix}${namespace}-${name}"
  # mongocli atlas dbusers create -u "${username}" -p "${password}" --role readWriteAnyDatabase --projectId "${projectId}" --scope "${scope}"

  for serviceName in "${services[@]}"; do
    echo kubectl get secret "user-config-${serviceName}" -n "${namespace}" -o json
    userConfig=$(kubectl get secret "user-config-${serviceName}" -n "${namespace}" -o json)

    if [ "${userConfig}" != "" ]; then
      base64NewValue=$(echo "${userConfig}" | jq -r '.data["user-config.json"]' | base64 -d | jq '.bigdata.login="'"${username}"'"' | jq '.caches.cache.login="'"${username}"'"' | base64)
      echo "${userConfig}" | jq '.data["user-config.json"]="'"${base64NewValue}"'"' | kubectl apply -f -
      podToKill=$(echo "${pods}" | jq -r '.items[].metadata | select(.name|test("'"${serviceName}"'")) | .name')
      kubectl delete pod "${podToKill}" -n "${namespace}"
    fi
  done
done

## Delete user
# mongoUsers=($(mongocli atlas dbusers list | jq -r '.[].username | select(.|test("loop-compta-test")) | .'))
# for mongoUser in "${mongoUsers[@]}"; do
#   mongocli atlas dbusers delete "${mongoUser}"
# done
