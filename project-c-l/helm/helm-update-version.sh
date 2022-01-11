#!/usr/bin/env bash

set -e # Exit on any error

source "$(dirname $0)/helm-library.sh"

# No argument is filled in
if [ $# -eq 0 ] || [ $# -gt 2 ]; then
  echo -e "\nPlease choose how to increment the version by using one of the following values:"
  echo -e "  - major (1.0.0)"
  echo -e "  - minor (0.1.0)"
  echo -e "  - patch (0.0.1)\n"
  echo -e "You select a specific chart as a second argument.\n"
  echo -e "How it works?"
  echo -e "$0 <major|minor|patch> [service]\n"
  exit 1
fi

# Mode
mode=$1
echo -e "\nUpdate charts version: ${mode}"

# Specific chart
if [ $# -eq 2 ]; then
  charts=("$2")
  echo -e "\nChart selected: $2\n"
# Updated charts
else
  charts=($(get_charts "updated"))
  echo -e "\nCharts found: ${#charts[@]}\n"
fi

for chart in "${charts[@]}"; do
  old_version=$(get_chart_version "${chart}")
  new_version=$(inc_version "${chart}" "${mode}")
  echo "${chart} - ${old_version} --> ${new_version}"

  # Remove the alias "template:" and all first indents of 2 spaces
  # MacOS
  if [ "$(uname -s)" == "Darwin" ]; then
      sed -i "" "s/^version:.*$/version: ${new_version}/g" "${chart}/Chart.yaml"
  # Others
  else
      sed -i "s/^version:.*$/version: ${new_version}/g" "${chart}/Chart.yaml"
  fi
done
