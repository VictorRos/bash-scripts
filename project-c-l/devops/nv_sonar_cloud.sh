#!/bin/bash

set -e

############################################################################################
#######################          Update sonar configuration token           ################
#######################    Update the token azure devops on sonar for PR    ################
############################################################################################

######## BEGIN FILL #######

# Your cookie/session for sonar :) (you can retrieve it when you access Sonar, go to the url of sonar manually)
XSRF_TOKEN="####"
JWT_SESSION="####"

# Azure DevOps token for sonar (token of svcprodloop account)
SVCPRODLOOP_TOKEN="####"

# TODO: Get list from an API call
PROJECTS=(
  "cegid.loop.cae"
  "cegid.loop.compta.arpegeweb"
  "cegid.loop.core-config"
  "cegid.loop.core-parametre"
  "cegid.loop.gi"
  "cegid.loop.npm.cfonb-retention"
  "cegid.loop.npm.cfonb"
  "cegid.loop.npm.crypto"
  "cegid.loop.npm.docker-compose-utils"
  "cegid.loop.npm.eslint-plugin"
  "cegid.loop.npm.eslint"
  "cegid.loop.npm.log-metrics"
  "cegid.loop.npm.logger"
  "cegid.loop.npm.microsoft-login"
  "cegid.loop.npm.react"
  "cegid.loop.npm.utils"
  "cegid.loop.paie"
  "cegid.loop.pia.account_class_predictor"
  "cegid.loop.pia.accountclassifier_predict"
  "cegid.loop.pia.accountclasspredictortrain"
  "cegid.loop.pia.accountclasspreprocess"
  "cegid.loop.pia.accountpredictor"
  "cegid.loop.pia.accountpredictortrain"
  "cegid.loop.pia.archiver"
  "cegid.loop.pia.bankaccountpredict"
  "cegid.loop.pia.bankfeatureengineering"
  "cegid.loop.pia.bankthirdpartypredict"
  "cegid.loop.pia.common"
  "cegid.loop.pia.core"
  "cegid.loop.pia.documentclassifierpredict"
  "cegid.loop.pia.documentclassifiertrain"
  "cegid.loop.pia.emailprocessor"
  "cegid.loop.pia.engine"
  "cegid.loop.pia.generator"
  "cegid.loop.pia.languageclassifierpredict"
  "cegid.loop.pia.languageclassifiertrain"
  "cegid.loop.pia.multiaccountclasspredict"
  "cegid.loop.pia.pdf_splitter_predict"
  "cegid.loop.pia.qualityextraction_predict"
  "cegid.loop.pia.queryhandler"
  "cegid.loop.pia.sale_purchase_classifier_predict"
  "cegid.loop.pia.spwatcher"
  "cegid.loop.pia.supplierclasspredict"
  "cegid.loop.pia.thirdpartyclassifier"
  "cegid.loop.publicrdd"
  "cegid.loop.yupana.EmailCollection"
  "cegid.loop.yupana.framework"
  "cegid.loop.yupana.PIA-FileCollector"
  "cegid.loop.yupana.PiaAccountingConsumer"
  "cegid.loop.yupana.PiaBKCollection"
  "cegid.loop.yupana.PiaBKRegistration"
  "cegid.loop.yupana.PiaBKScheduling"
  "cegid.loop.yupana.PiaBKStatementAggregator"
  "cegid.loop.yupana.PiaBKTransactionEnrichment"
  "cegid.loop.yupana.PiaEmailProcessor"
  "cegid.loop.yupana.PiaEntryGenerator"
  "cegid.loop.yupana.PiaEntryReconciliation"
  "cegid.loop.yupana.PIALOOPsharepointmanager"
  "cegid.loop.yupana.PiaUIAPI"
  "cegid.loop.yupana.PiaUIApp"
  "cegid.loop.yupana.PiaUIGQL"
  "cegid.loop.yupana.publicApi"
  "cegid.loop.yupana.ypn-log-metrics"
  "cegid.loop.yupana.ypn-mongo-maintenance"
)

######## END FILL #######

curl_call() {
  local project=$1
  local data_raw=$2

  curl 'https://sonarcloud.io/api/settings/set' \
    -H 'Connection: keep-alive' \
    -H 'sec-ch-ua: "Chromium";v="92", " Not A;Brand";v="99", "Google Chrome";v="92"' \
    -H 'Accept: application/json' \
    -H 'DNT: 1' \
    -H "X-XSRF-TOKEN: ${XSRF_TOKEN}" \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.107 Safari/537.36' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'Origin: https://sonarcloud.io' \
    -H 'Sec-Fetch-Site: same-origin' \
    -H 'Sec-Fetch-Mode: cors' \
    -H 'Sec-Fetch-Dest: empty' \
    -H "Referer: https://sonarcloud.io/project/settings?category=pull_request&id=${project}" \
    -H 'Accept-Language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7' \
    -H "Cookie: XSRF-TOKEN=${XSRF_TOKEN}; JWT-SESSION=${JWT_SESSION}" \
    -H 'sec-gpc: 1' \
    --data-raw "${data_raw}" \
    --compressed
}

for project in "${PROJECTS[@]}"; do
  # Set provider to "Azure DevOps Services"
  curl_call "${project}" "key=sonar.pullrequest.provider&component=${project}&value=Azure%20DevOps%20Services"

  # Set secured token to SvcProdLoop token
  curl_call "${project}" "key=sonar.pullrequest.vsts.token.secured&component=${project}&value=${SVCPRODLOOP_TOKEN}"
done
