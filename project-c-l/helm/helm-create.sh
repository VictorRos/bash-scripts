#!/usr/bin/env bash

set -e # Exit on any error

__dirname=$(dirname $0)

source "${__dirname}/helm-library.sh"

####################################################################################################
# CHECK PARAMETERS
####################################################################################################
if [ $# -eq 1 ]; then
  typology="library-deployment"
elif [ $# -eq 2 ]; then
  if [ "$2" = "library-deployment" ] \
    || [ "$2" = "library-cronJob" ] \
    || [ "$2" = "library-scaledJob" ]; then
    typology=$2
  elif [ "$2" = "template-microservice" ] \
    || [ "$2" = "template-microservice-job" ]; then
    error "Typology $2 is not supported anymore."
    exit 1
  else
    error "Unknow typology $2."
    exit 1
  fi
else
  error "How it works?\n"
  error "$0 <chart_name> [typology]\n"
  error "Create a Helm chart."
  error "<chart_name> : Helm chart name to create"
  error "<typology> : Typology to use among library-deployment, library-cronJob and library-scaledJob"
  exit 1
fi

chart_name=$1

info "Typology selected: ${typology}\n"

# Create basic Helm chart
helm create ${chart_name}
# Remove unnecessary files
rm -rf "${chart_name}/charts" "${chart_name}/Chart.lock" "${chart_name}/templates"

info "\nCopy Chart.yaml from ${typology}"
cp "${typology}/Chart.yaml" "${chart_name}/Chart.yaml"

info "Copy values-${typology}.yaml from helm-boiler-templates"
cp "${__dirname}/helm-boiler-plates/values-${typology}.yaml" "${chart_name}/values.yaml"

info "Copy manifest-${typology}.yaml from helm-boiler-templates"
mkdir "${chart_name}/templates"
cp "${__dirname}/helm-boiler-plates/templates/manifest.yaml" "${chart_name}/templates/manifest.yaml"
sed -i "" "s/__library__/${typology##"library-"}/" "${chart_name}/templates/manifest.yaml"

info "Copy integration folder from helm-boiler-templates"
rm -rf "${chart_name}/integration"
cp -R "${__dirname}/helm-boiler-plates/integration" "${chart_name}"

info "Copy test folder from helm-boiler-templates"
rm -rf "${chart_name}/test"
cp -R "${__dirname}/helm-boiler-plates/test" "${chart_name}"

# Get typology version
typology_version=$(get_chart_version "${typology}")

##### Chart.yaml #####
info "Adapt Chart.yaml"

# Update file
sed -i "" "s/^name: ${typology}$/name: ${chart_name}/" "${chart_name}/Chart.yaml"
sed -i "" "s/^description: .*$/description: Helm chart ${chart_name} for Kubernetes/" "${chart_name}/Chart.yaml"
sed -i "" "s/^type: library$/type: application/" "${chart_name}/Chart.yaml"
sed -i "" "s/^version: .*$/version: 0.1.0/" "${chart_name}/Chart.yaml"
sed -i "" "s/^appVersion: .*$/appVersion: 1.0.0/" "${chart_name}/Chart.yaml"
# Update dependency
sed -i "" "s/^\(....name: \).*$/\1${typology}/" "${chart_name}/Chart.yaml"
sed -i "" "s/^\(....version: \).*$/\1^${typology_version}/" "${chart_name}/Chart.yaml"

##### values.yaml #####
info "Adapt values.yaml"

# Update file
sed -i "" "s/${typology}/${chart_name}/g" ${chart_name}/values.yaml
