#!/usr/bin/env bash

# Colors (copy from nv_color.sh)
PREFIX_COLOR="\x1b"
NO_COLOR="${PREFIX_COLOR}[0m"
COLOR_BLUE="${PREFIX_COLOR}[34m"
COLOR_GREEN="${PREFIX_COLOR}[32m"
COLOR_RED="${PREFIX_COLOR}[31m"
COLOR_YELLOW="${PREFIX_COLOR}[33m"

LIBRARY_COMMON="library-common"
LIBRARY_CRONJOB="library-cronJob"
LIBRARY_SCALEDJOB="library-scaledJob"
LIBRARY_DEPLOYMENT="library-deployment"
TEMPLATE_MICROSERVICE="template-microservice"
TEMPLATE_MICROSERVICE_JOB="template-microservice-job"
NO_TEMPLATE="no-template"

HELM_VALID_FOLDER="helm-valid"

CURRENT_BRANCH_SHA=$(git rev-parse --verify HEAD)
LAST_BUILD_TAG_SHA=$(git rev-list -n 1 tags/last-build)

####################################################################################################
# Tools
####################################################################################################
yq() {
  docker run --rm -v "${PWD}":/workdir mikefarah/yq:latest "$@"
}

####################################################################################################
# ADO output / Shell output
####################################################################################################
section() {
  # MacOS
  if [ "$(uname -s)" = "Darwin" ]; then
    echo -e "${COLOR_GREEN}$1${NO_COLOR}\n"
  # Others
  else
    echo -e "##[section]$1\n"
  fi
}

start_group() {
  # MacOS
  if [ "$(uname -s)" = "Darwin" ]; then
    echo -e "${COLOR_YELLOW}$1${NO_COLOR}\n"
  # Others
  else
    echo -e "##[group]$1"
  fi
}

end_group() {
  # MacOS
  if [ "$(uname -s)" = "Darwin" ]; then
    echo -e ""
  # Others
  else
    echo -e "##[endgroup]"
  fi
}

info() {
  echo -e "${COLOR_BLUE}$1${NO_COLOR}"
}

warn() {
  echo -e "${COLOR_YELLOW}$1${NO_COLOR}"
}

error() {
  # MacOS
  if [ "$(uname -s)" = "Darwin" ]; then
    echo -e "${COLOR_RED}$1${NO_COLOR}"
  # Others
  else
    echo -e "##vso[task.logissue type=error] $1"
  fi
}

####################################################################################################
# Util methods
####################################################################################################
# Returns true if it is a chart, false otherwise.
# <chart> = Helm chart.
# Usage: is_a_chart <chart>
is_a_chart() {
  local chart=$1

  local result=$(find . \
    -path "*${chart}*" \
    -type f \
    -name "Chart.yaml" \
    -maxdepth 2 | sort)

  if [ "${result}" = "" ]; then
    echo false
  else
    echo true
  fi
}

# Check if Helm chart has been updated.
# Use git commands to check if Helm chart has been updated.
# NOTE: Files must be commited to have the git command works.
# <chart> = Helm chart.
# Usage: has_chart_been_updated <chart>
has_chart_been_updated() {
  local chart=$1
  local result=$(git diff "${LAST_BUILD_TAG_SHA}" "${CURRENT_BRANCH_SHA}" "${chart}")

  if [ "${result}" = "" ]; then echo false; else echo true; fi
}

# Check if Helm chart version has been updated.
# Use git commands to check if version has been updated.
# NOTE: Files must be commited to have the git command works.
# <chart> = Helm chart.
# Usage: is_chart_version_updated <chart>
is_chart_version_updated() {
  local chart=$1
  local result=$(git diff "${LAST_BUILD_TAG_SHA}" "${CURRENT_BRANCH_SHA}" "${chart}/Chart.yaml" \
    | { grep "version:" || true; })

  if [ "${result}" = "" ]; then echo false; else echo true; fi
}

# Get updated files.
# Use git commands to get charts.
# NOTE: Files must be commited to have the git command works.
# Usage: get_updated_files
get_updated_files() {
  git diff --name-only "${LAST_BUILD_TAG_SHA}" "${CURRENT_BRANCH_SHA}"
}

# Get updated Helm charts.
# Use git commands to get charts.
# NOTE: Files must be commited to have the git command works.
# <mode> = Templates to validate.
# - all: All templates.
# - updated: Updated templates.
# Usage: get_charts <mode>
get_charts() {
  if [ "$1" = "all" ]; then
    find . \
      -not -path "." \
      -not -path "*.externalNames" \
      -not -path "*.git" \
      -not -path "*.pipelines" \
      -not -path "*library-*" \
      -not -path "*template-microservice*" \
      -type d \
      -maxdepth 1 \
      -exec basename {} \; | sort
  elif [ "$1" = "updated" ]; then
    # 1/ Remove everything after the first slash (/)
    # 2/ Remove duplicates
    # 3/ Ignore files that contain a dot in their names (.), libraries and templates
    echo "$(get_updated_files)" \
      | sed -e "s/\(^[^\/]*\).*/\1/g" \
      | awk '!a[$0]++' \
      | { grep -v -e "\." -e "library-*" -e "template-microservice*" || true; }
  fi
}

# Get updated Helm Library charts.
# Use git commands to get charts.
# NOTE: Files must be commited to have the git command works.
# <mode> = Templates to validate.
# - all: All templates.
# - updated: Updated templates.
# Usage: get_libraries <mode>
get_libraries() {
  if [ "$1" = "all" ]; then
    find . \
      -path "*library-*" \
      -type d \
      -maxdepth 1 \
      -exec basename {} \; | sort
  elif [ "$1" = "updated" ]; then
    # 1/ Remove everything after the first slash (/)
    # 2/ Remove duplicates
    # 3/ Ignore libraries
    echo "$(get_updated_files)" \
      | sed -e "s/\(^[^\/]*\).*/\1/g" \
      | awk '!a[$0]++' \
      | { grep -e "library-*" || true; }
  fi
}

# Get updated old Helm charts' templates.
# Use git commands to get charts.
# NOTE: Files must be commited to have the git command works.
# <mode> = Templates to validate.
# - all: All templates.
# - updated: Updated templates.
# Usage: get_templates <mode>
get_templates() {
  if [ "$1" = "all" ]; then
    find . \
      -path "*template-microservice*" \
      -type d \
      -maxdepth 1 \
      -exec basename {} \; | sort
  elif [ "$1" = "updated" ]; then
    # 1/ Remove everything after the first slash (/)
    # 2/ Remove duplicates
    # 3/ Ignore templates
    echo "$(get_updated_files)" \
      | sed -e "s/\(^[^\/]*\).*/\1/g" \
      | awk '!a[$0]++' \
      | { grep -e "template-microservice" || true; }
  fi
}

# Get version of a Helm chart.
# <chart> = Helm chart.
# Usage: get_chart_version <chart>
get_chart_version() {
  local chart=$1
  yq e '.version' "${chart}/Chart.yaml"
}

# Get major version of a Helm chart.
# <chart> = Helm chart.
# Usage: get_chart_major_version <chart>
get_chart_major_version() {
  local chart=$1
  get_chart_version "${chart}" | sed "s/\([0-9]*\)\.[0-9]*\.[0-9]*/\1/"
}

# Increment version version of a Helm chart.
# <chart> = Helm chart.
# <mode> = major | minor | patch
# Usage: inc_version <chart> <mode>
inc_version() {
  local chart=$1
  local mode=$2 # major, minor or patch
  # Get parts of the current version
  local current_version=$(get_chart_version "${chart}")
  local parts=(${current_version//./ })
  local major=${parts[0]}
  local minor=${parts[1]}
  local patch=${parts[2]}
  # Handle major version
  if [ "${mode}" = "major" ]; then
    major=$((major + 1))
    # Reset minor and patch
    minor=0
    patch=0
  # Handle minor version
  elif [ "${mode}" = "minor" ]; then
    minor=$((minor + 1))
    # Reset patch
    patch=0
  # Handle patch version
  elif [ "${mode}" = "patch" ]; then
    patch=$((patch + 1))
  fi
  echo "${major}.${minor}.${patch}"
}

# Get typology for a Helm chart.
# WARNING: Works only if chart has only one dependency.
# <chart> = Helm chart.
# Usage: get_typology_name <chart>
get_typology_name() {
  local chart=$1
  local typology=$(yq e '.dependencies[].name' "${chart}/Chart.yaml")

  # Charts with no dependencies
  if [ "${typology}" = "" ] || [ "${typology}" = "null" ]; then
    echo "${NO_TEMPLATE}"
  else
    echo "${typology}"
  fi
}

# Get typology version for a Helm chart.
# WARNING: Works only if chart has only one dependency.
# <chart> = Helm chart.
# Usage: get_typology_version <chart>
get_typology_version() {
  local chart=$1
  yq e '.dependencies[].version' "${chart}/Chart.yaml"
}

# Get typology major version for a Helm chart.
# <chart> = Helm chart.
# Usage: get_typology_major_version <chart>
get_typology_major_version() {
  local chart=$1
  yq e '.dependencies[].version | sub(".*(\d+)\.\d+\.\d+.*", "${1}")' "${chart}/Chart.yaml"
}

# Get charts that used this Helm chart typology.
# <typology> = Typology.
# Usage: get_charts_from_typology <typology>
get_charts_from_typology() {
  local typology=$1
  grep -irl --exclude-dir="${HELM_VALID_FOLDER}" --include=Chart.yaml "^.\+name: ${typology}$" . | sed "s/\.\/\([^/]*\).*/\1/" | sort
}

# Check if "--dependency-update" option is requested.
# <typology> - Typology.
# Usage: request_dependency_update <typology>
request_dependency_update() {
  local typology=$1

  case "${typology}" in
    *library-*)
      echo true
      ;;
    *template-microservice*)
      echo true
      ;;
    *)
      echo false
      ;;
  esac
}
