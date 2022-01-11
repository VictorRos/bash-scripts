#!/usr/bin/env bash

set -e # Exit on any error

source "$(dirname $0)/helm-library.sh"

# Firstly, you must be connected to Azure (using azure-cli) and you should select a context of a cluster Kubernetes

# Helm chart typologies:
# - No template
# - Using template-microservice
# - Using template-microservice-job
# - Using library-common (library-cronJob, library-scaledJob and library-deployment)
# - Using library-cronJob
# - Using library-deployment
# - Using library-scaledJob
#
# Note: Libraries cannot be tested themselves, but they can be tested by testing Helm charts that use the library.

####################################################################################################
# OLD TEMPLATES
####################################################################################################
# Validate templates.
# <mode> = Templates to validate.
# - all: All templates.
# - updated: Updated templates.
# validate_templates <mode>
validate_templates() {
  local mode=$1

  section "Old Templates"
  local templates=($(get_templates "${mode}"))

  if [ ${#templates[@]} -eq 0 ]; then
    echo -e "No old templates.\n"
  else
    echo -e "Old templates: ${#templates[@]} (${templates[*]})\n"
  fi

  # For each "templates"
  #   Get charts using the template
  #   Buld helm options
  #   For each chart
  #     Validate
  exit_code=0
  for template in "${templates[@]}"; do
    echo -e "Get charts using ${template}\n"
    local charts=($(get_charts_from_typology "${template}"))

    if [ ${#charts[@]} -eq 0 ]; then
      echo -e "No charts using ${template}\n"
    else
      echo -e "Charts found: ${#charts[@]} (${charts[*]})\n"
    fi

    for chart in "${charts[@]}"; do
      start_group "${chart}"

      (validate_chart "${chart}" "${template}") || exit_code=1

      end_group
    done
  done

  exit ${exit_code}
}

####################################################################################################
# LIBRARIES
####################################################################################################
# Validate libraries.
# <mode> = Libraries to validate.
# - all: All libraries.
# - updated: Updated libraries.
# validate_libraries <mode>
validate_libraries() {
  local mode=$1

  section "Libraries"
  local libraries=($(get_libraries "${mode}"))

  # Remove library-common from the list because we only validate libraries used in charts.
  # library-common is validated through other libraries, so we override libraries array with all libraries except library-commmon.
  if [[ " ${libraries[*]} " =~ " ${LIBRARY_COMMON} " ]]; then
    libraries=(
      "${LIBRARY_CRONJOB}"
      "${LIBRARY_DEPLOYMENT}"
      "${LIBRARY_SCALEDJOB}"
    )
  fi

  if [ ${#libraries[@]} -eq 0 ]; then
    echo -e "No libraries.\n"
  else
    echo -e "Libraries: ${#libraries[@]} (${libraries[*]})\n"
  fi

  # For each "libraries"
  #   Get charts using the library
  #   Buld helm options
  #   For each chart
  #     Validate
  exit_code=0
  for library in "${libraries[@]}"; do
    echo -e "Get charts using ${library}\n"
    local charts=($(get_charts_from_typology "${library}"))

    if [ ${#charts[@]} -eq 0 ]; then
      echo -e "No charts using ${library}.\n"
    else
      echo -e "Charts found: ${#charts[@]} (${charts[*]})\n"
      cleanup_typology "${library}"
    fi

    for chart in "${charts[@]}"; do
      start_group "${chart}"

      (validate_chart "${chart}" "${library}") || exit_code=1

      end_group
    done
  done

  exit ${exit_code}
}

####################################################################################################
# CHARTS
####################################################################################################
# Validate charts.
# <mode> = Helm charts to validate.
# - all: All charts.
# - updated: Updated charts.
# validate_charts <mode>
validate_charts() {
  local mode=$1

  section "Charts"
  local charts=($(get_charts "${mode}"))

  if [ ${#charts[@]} -eq 0 ]; then
    echo -e "No charts.\n"
  else
    echo -e "Charts found: ${#charts[@]} (${charts[*]})\n"
  fi

  # For each "charts"
  #   Get dependency (library, template or nothing)
  #   Buld helm options
  #   Validate the chart
  exit_code=0
  for chart in "${charts[@]}"; do
    start_group "${chart}"

    if [ -d "${chart}" ]; then
      (check_version_update "${chart}") || exit_code=1

      local typology=$(get_typology_name "${chart}")
      cleanup_typology "${typology}"
      (validate_chart "${chart}" "${typology}") || exit_code=1
    else
      echo -e "Helm chart ${chart} does not exist anymore"
    fi

    end_group
  done

  exit ${exit_code}
}

####################################################################################################
# VALIDATE CHART
####################################################################################################
validate_chart() {
  local chart=$1
  local typology=$2
  local exit_code=0
  local namespace=default
  local release_name="${chart}-${namespace}"

  ####################################################################################################
  # 1. Check mandatory files & version update
  ####################################################################################################
  (check_mandatory_files "${chart}" "${typology}") || exit_code=1

  ####################################################################################################
  # 2. Copy Helm chart files for modifications
  ####################################################################################################
  # Cleanup Helm chart before copy
  rm -rf "${HELM_VALID_FOLDER}/${chart}"
  rm -rf "${chart}/charts" "${chart}/Chart.lock"
  # Copy Helm chart files to avoid overriding original files :/
  cp -R "${chart}" "${HELM_VALID_FOLDER}/${chart}"

  ####################################################################################################
  # 3. Build Helm options
  ####################################################################################################
  # Common options
  helm_options=(
    -f "${HELM_VALID_FOLDER}/${chart}/values.yaml"
    --namespace "${namespace}"
    --validate
    --debug
  )

  # Handle dependency update option
  if [ "$(request_dependency_update "${typology}")" = "true" ]; then
    echo -e "Add --dependency-update option to helm command\n"
    helm_options+=(--dependency-update)
  fi

  # Do not override image tag and repository if there is a value
  echo -e "Check repository tag\n"
  image_repository=$(yq e '.image.repository' "${HELM_VALID_FOLDER}/${chart}/values.yaml")
  if [ "${image_repository}" = "null" ] || [ "${image_repository}" = "" ]; then
    # Specific for template-microservice and template-microservice-job
    if [ "${typology}" = "${TEMPLATE_MICROSERVICE}" ] || [ "${typology}" = "${TEMPLATE_MICROSERVICE_JOB}" ]; then
      helm_options+=(--set template.image.repository=nicvic.docker.io/${chart})
    else
      helm_options+=(--set image.repository=nicvic.docker.io/${chart})
    fi
  fi

  echo -e "Check image tag\n"
  image_tag=$(yq e '.image.tag' "${HELM_VALID_FOLDER}/${chart}/values.yaml")
  if [ "${image_tag}" = "null" ] || [ "${image_tag}" = "" ]; then
    # Specific for template-microservice and template-microservice-job
    if [ "${typology}" = "${TEMPLATE_MICROSERVICE}" ] || [ "${typology}" = "${TEMPLATE_MICROSERVICE_JOB}" ]; then
      helm_options+=(--set template.image.tag=quality)
    else
      helm_options+=(--set image.tag=quality)
    fi
  fi

  # Devel
  chart_version=$(get_chart_version "${chart}")
  # If version contains "-" then helm command requests "--devel" option
  if [ -z "${chart_version##*-*}" ]; then
    echo -e "Add --devel option to helm command\n"
    helm_options+=(--devel)
  fi

  ####################################################################################################
  # 4. Handle validation with current typology or the one in Artifactory
  ####################################################################################################
  # Predicate: If majors are different, we use the template published in the Artifactory.
  # We assume in this case that the template has its major version superior to the service major version.
  # Otherwise, if majors are equal, we must update the dependency to use local template files.
  local typology_major_version=$(get_typology_major_version "${chart}")
  local typology_major_version_in_chart=$(get_chart_major_version "${typology}")

  echo -e "Typology major version: ${typology_major_version}"
  echo -e "Typology major version in ${chart}: ${typology_major_version_in_chart}\n"

  if [ "${typology}" != "${NO_TEMPLATE}" ] && [ "${typology_major_version_in_chart}" = "${typology_major_version}" ]; then
    echo -e "Validation with local ${typology}\n"

    local typology_version=$(get_chart_version "${typology}")
    # MacOS
    if [ "$(uname -s)" = "Darwin" ]; then
      sed -i "" "s/https:\/\/cegid.jfrog.io\/cegid\/loop-helmv/file:\/\/..\/..\/${typology}/" "${HELM_VALID_FOLDER}/${chart}/Chart.yaml"
      sed -i "" "s/^\(    version: \([~^]\)\{0,1\}\)[0-9]*\.[0-9]*\.[0-9]*/\1${typology_version}/" "${HELM_VALID_FOLDER}/${chart}/Chart.yaml"
    # Others
    else
      sed -i "s/https:\/\/cegid.jfrog.io\/cegid\/loop-helmv/file:\/\/..\/..\/${typology}/" "${HELM_VALID_FOLDER}/${chart}/Chart.yaml"
      sed -i "s/^\(    version: \([~^]\)\{0,1\}\)[0-9]*\.[0-9]*\.[0-9]*/\1${typology_version}/" "${HELM_VALID_FOLDER}/${chart}/Chart.yaml"
    fi
  else
    echo -e "Validation with ${typology} from Artifactory\n"
  fi

  ####################################################################################################
  # 5. Helm validation
  ####################################################################################################
  # MacOS
  if [ "$(uname -s)" = "Darwin" ]; then
    echo -e "${COLOR_BLUE}helm template ${release_name} ${HELM_VALID_FOLDER}/${chart} ${helm_options[*]}${NO_COLOR}\n"
  # Others
  else
    echo -e "##[command]helm template ${release_name} ${HELM_VALID_FOLDER}/${chart} ${helm_options[*]}\n"
  fi

  (helm template "${release_name}" "${HELM_VALID_FOLDER}/${chart}" "${helm_options[@]}") || exit_code=1

  # Helm chart is not valid
  if [ ${exit_code} -eq 1 ]; then
    echo "" # To add empty line
    error "${chart} is not valid!\n"
  fi

  exit ${exit_code}
}

# Check mandatory files for validation.
# <chart> = Helm chart.
# <typology> - Typology.
# Usage: check_mandatory_files <chart> <typology>
check_mandatory_files() {
  local chart=$1
  local typology=$2
  local missing_mandatory_files=false

  # Common to all Helm charts
  if [ ! -f "${chart}/Chart.yaml" ]; then
    error "Missing mandatory file: ${chart}/Chart.yaml\n"
    missing_mandatory_files=true
  fi
  if [ ! -f "${chart}/values.yaml" ]; then
    error "Missing mandatory file: ${chart}/values.yaml\n"
    missing_mandatory_files=true
  fi

  # Specific libraries and templates
  if [ "${typology}" != "${NO_TEMPLATE}" ]; then
    if [ ! -f "${chart}/.helmignore" ]; then
      error "Missing mandatory file: ${chart}/.helmignore\n"
      missing_mandatory_files=true
    fi
  fi

  # Specific libraries
  if [ "${typology}" != "${NO_TEMPLATE}" ] \
    && [ "${typology}" != "${TEMPLATE_MICROSERVICE}" ] \
    && [ "${typology}" != "${TEMPLATE_MICROSERVICE_JOB}" ]; then
    if [ ! -f "${chart}/templates/manifest.yaml" ]; then
      error "Missing mandatory file: ${chart}/templates/manifest.yaml\n"
      missing_mandatory_files=true
    fi
  fi

  # Exit 1 if at least one mandatory file is missing
  if [ "${missing_mandatory_files}" = "true" ]; then
    exit 1
  fi
}

# Check if Chart version has been updated.
# <chart> = Helm chart.
# Usage: check_version_update <chart>
check_version_update() {
  local chart=$1

  if [ $(has_chart_been_updated "${chart}") = "true" ]; then
    if [ $(is_chart_version_updated "${chart}") = "false" ]; then
      error "Chart version for ${chart} has not been updated\n"
      exit 1
    else
      echo -e "Chart version for ${chart} has been updated\n"
    fi
  fi
}

# Delete sub folder charts and Chart.lock from typology folder.
# Regenerate library-common archive into typology folder.
# <typology> - Typology.
# Usage: cleanup_typology <typology>
cleanup_typology() {
  local typology=$1

  # Cleanup only for libraries
  if [ "${typology}" != "${NO_TEMPLATE}" ] \
    && [ "${typology}" != "${TEMPLATE_MICROSERVICE}" ] \
    && [ "${typology}" != "${TEMPLATE_MICROSERVICE_JOB}" ]; then
    # Cleanup Helm chart folder: delete sub folder charts and Chart.lock
    rm -rf "${typology}/charts" "${typology}/Chart.lock"

    echo -e "Packaging ${LIBRARY_COMMON} to ${typology}/charts...\n"
    helm package "${LIBRARY_COMMON}" -d "${typology}/charts"
    echo ""
  fi
}

####################################################################################################
# HELM CHART VALIDATION MANAGER
####################################################################################################
# Helm validate manager
# <mode> = Mode.
# - all: All Helm charts.
# - updated: All updated Helm charts.
# - templates: Only updated Helm charts using templates.
# - libraries: Only updated Helm charts using libraries.
# - charts: Only updated charts.
# - <chart_name>: A specific chart name.
# validate_manager <mode>
validate_manager() {
  if [ $# -eq 0 ] || [ "$1" = "" ]; then
    error "Mode is required.\n"
    error "Mode:"
    error "- all: All Helm charts."
    error "- updated: All updated Helm charts."
    error "- templates: Only updated Helm charts using templates."
    error "- libraries: Only updated Helm charts using libraries."
    error "- charts: Only updated charts."
    error "- <chart_name>: A specific chart name."
    exit 1
  fi

  local mode=$1

  case "${mode}" in
    all)
      validate_templates "all"
      validate_libraries "all"
      validate_charts "all"
      ;;
    updated)
      validate_templates "updated"
      validate_libraries "updated"
      validate_charts "updated"
      ;;
    templates)
      validate_templates "updated"
      ;;
    libraries)
      validate_libraries "updated"
      ;;
    charts)
      validate_charts "updated"
      ;;
    *)
      if [ $(is_a_chart "${mode}") = "true" ]; then
        local exit_code=0

        (check_version_update "${mode}") || exit_code=1

        local typology=$(get_typology_name "${mode}")
        cleanup_typology "${typology}"
        (validate_chart "${mode}" "${typology}") || exit_code=1

        exit ${exit_code}
      else
        error "${mode} is not a Helm chart."
        exit 1
      fi
      ;;
  esac
}

# Create directory to store charts before modifications for validation
rm -rf "${HELM_VALID_FOLDER}"
mkdir "${HELM_VALID_FOLDER}"

validate_manager "$1"

rm -rf "${HELM_VALID_FOLDER}"
