#!/bin/bash

# shellcheck disable=2001

set -e

source "$(dirname "${BASH_SOURCE[0]}")/nv_color.sh"

colors=($(printenv | sort | grep "\\${PREFIX_COLOR}"))

echo -e "Number of colors found: ${#colors[@]}\n"

for color in "${colors[@]}"; do
  # echo "color: ${color}"
  color_name=$(echo "${color}" | sed "s/^\([^=]*\)=.*$/\1/")
  # Ignore those 2 variables
  if [ "${color_name}" != "PREFIX_COLOR" ] && [ "${color_name}" != "NO_COLOR" ]; then
    color_value=$(echo "${color}" | sed "s/^[^=]*=\([^=]*\)/\1/")
    echo -e "${color_value}${color_name}${NO_COLOR}"
  fi
done
