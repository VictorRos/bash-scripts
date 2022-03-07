#!/usr/bin/env bash

set -e # Exit on any error

source "$(dirname $0)/helm-library.sh"

# You can chose to migrate one or every charts
if [ $# -eq 1 ];then
  charts=("$1")
else
  charts=($(get_charts "all"))
fi

# This variable is the ID of the library "Loop-charts-override-dev" on azure devops
group_list=492

ado_library_values=$(az pipelines variable-group show --group-id ${group_list} --organization https://dev.azure.com/cegid --project Loop)

for chart in "${charts[@]}"; do
  echo -e "Helm chart: ${chart}\n"

  typology=$(get_typology_name "${chart}")

  new_typology=""
  if [ "${typology}" = "${TEMPLATE_MICROSERVICE}" ]; then
    new_typology="${LIBRARY_DEPLOYMENT}"
  elif [ "${typology}" = "${TEMPLATE_MICROSERVICE_JOB}" ]; then
    new_typology="${LIBRARY_CRONJOB}"
  fi

  # Migration
  if [ "${new_typology}" != "" ]; then
    info "Migrate from ${typology} to ${new_typology}"

    ############### Modification du values.yaml ################@

    echo -e "\n***** Update values.yaml *****\n"

    echo -e "Delete 'template:'"
    sed -i "" "/template:/d" "${chart}/values.yaml"

    echo -e "Add context production"
    sed -i "" "s/  appVersion: .*/\n  context: production/" "${chart}/values.yaml"

    echo -e "Image - Remove pullPolicy and pullSecret"
    sed -i "" "/pullPolicy:/d" "${chart}/values.yaml"
    sed -i "" "/pullSecret:/d" "${chart}/values.yaml"

    echo -e "Autoscaling - Remove replicas if they equal default value"
    sed -i "" '/replicaCount: 1$/d' "${chart}/values.yaml"
    sed -i "" '/minReplicas: 1$/d' "${chart}/values.yaml"
    sed -i "" '/maxReplicas: 1$/d' "${chart}/values.yaml"
    sed -i "" '/minBudgetReplicas: 0$/d' "${chart}/values.yaml"

    must_update_annotations_manually=$(yq e '.ingress.annotations' "${chart}/values.yaml")
    if [ "${must_update_annotations_manually}" != "null" ]; then
      warn "Ingress annotations must be updated manually. You can follow helm-migration.md"
    fi

    rewrite_target=$(yq e '.ingress.annotations["nginx.ingress.kubernetes.io/rewrite-target"]' "${chart}/values.yaml")
    if [ "${rewrite_target}" != "null" ]; then
      echo -e "Ingress - Handle rewrite target"
      sed -i "" -e "/.*ingress:.*$/,/.*enabled:.*$/!b
      /.*enabled:.*$/a \ 
    rewriteTarget: ${rewrite_target}" "${chart}/values.yaml"
      sed -i "" "/Override some annotations from template-microservice/d" "${chart}/values.yaml"
      sed -i "" "/nginx.ingress.kubernetes.io/rewrite-target/d" "${chart}/values.yaml"
    fi

    echo -e "Ingress - Remove tls bloc"
    sed -i "" -e 'H;x;/^\(  *\)\n\1/{s/\n.*//;x;d;}' -e 's/.*//;x;/tls:/{s/^\( *\).*/ \1/;x;d;}' "${chart}/values.yaml"

    echo -e "Ingress - Remove hosts bloc"
    sed -i "" -e 'H;x;/^\(  *\)\n\1/{s/\n.*//;x;d;}' -e 's/.*//;x;/hosts:/{s/^\( *\).*/ \1/;x;d;}' "${chart}/values.yaml"

    echo -e "ConfigMap - Update external ConfigMap bloc"
    sed -i "" "s/      name: environment-variable/      configMap:\n        - environment-variable/" "${chart}/values.yaml"

    echo -e "Re-indent"
    sed -i "" "s/^  //" "${chart}/values.yaml"

    ############### Modification du Chart.yaml ################@

    echo -e "\n***** Update Chart.yaml *****\n"

    echo -e "Remove alias"
    sed -i "" "/alias: template/d" "${chart}/Chart.yaml"
    echo -e "Update dependency name with ${new_typology}"
    sed -i "" "s/${TEMPLATE_MICROSERVICE}.*/${new_typology}/" "${chart}/Chart.yaml"
    new_typology_version=$(get_chart_version "${new_typology}")
    echo -e "Update dependency version to ^${new_typology_version}"
    sed -i "" "s/^....version: .*/    version: \^${new_typology_version}/" "${chart}/Chart.yaml"

    ############### Helm override ################@

    echo -e "\n***** Helm override *****\n"

    echo -e "Copy boiler plates files for helm overrides"
    cp -R .pipelines/scripts/helm-boiler-plates/integration "${chart}"
    cp -R .pipelines/scripts/helm-boiler-plates/test "${chart}"
    cp -R .pipelines/scripts/helm-boiler-plates/templates "${chart}"
    sed -i "" "s/__library__/${new_typology##"library-"}/" "${chart}/templates/manifest.yaml"

    # Add specific autoscaling for test and integration if it is a library-deployment
    if [ "${new_typology}" = "library-deployment" ]; then
      maxReplicas=$(yq e '.autoscaling.maxReplicas' "${chart}/values.yaml")
      # Determine maxReplicas for test and integration dependending on maxReplicas value in values.yaml
      if [ "${maxReplicas}" = "null" ]; then
        maxReplicasIntegration=1
        maxReplicasTest=1
      elif [ "${maxReplicas}" -eq 2 ]; then
        maxReplicasIntegration=2
        maxReplicasTest=2
      else
        maxReplicasIntegration=3
        maxReplicasTest=2
      fi

      echo -e "Add specific autoscaling to integration/_common.yaml"
      echo -e "\nautoscaling:\n  replicaCount: 1\n  minReplicas: 1\n  maxReplicas: ${maxReplicasIntegration}" >> "${chart}/integration/_common.yaml"

      echo -e "Add specific autoscaling to test/_common.yaml"
      echo -e "\nautoscaling:\n  replicaCount: 1\n  minReplicas: 1\n  maxReplicas: ${maxReplicasTest}" >> "${chart}/test/_common.yaml"
    fi

    echo -e "Add dev resources to test/_common.yaml"
    echo "
resources:
  limits: 
    cpu: $(echo "${ado_library_values}" | jq -r ".variables[\"${chart//\/}-cpu-limits\"].value")
    memory: $(echo "${ado_library_values}" | jq -r ".variables[\"${chart//\/}-memory-limits\"].value")
  requests:
    cpu: $(echo "${ado_library_values}" | jq -r ".variables[\"${chart//\/}-cpu-requests\"].value")
    memory: $(echo "${ado_library_values}" | jq -r ".variables[\"${chart//\/}-memory-requests\"].value")" >> "${chart}/test/_common.yaml"
  else
    info "No migration for ${typology}\n"
  fi
done