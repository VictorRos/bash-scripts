#!/bin/bash

# shellcheck disable=SC2207

SCRIPT_NAME="${BASH_SOURCE[0]}"

get_directories() {
  local path=$1

  find "${path}" \
    -type d \
    -mindepth 1 \
    -maxdepth 4 \
    -not -path "*/.*" \
    -not -path "*/node_modules*" | sort -u
}

has_git_dir() {
  local path=$1
  [ -d "${path}/.git" ] && echo true || echo false
}

get_remote_url() {
  local path=$1
  git -C "${path}" config --local --get remote.origin.url
}

get_new_remote_url() {
  local mode=$1
  local remote_url=$2

  if [ "${mode}" = "ssh-to-https" ]; then
    # Before
    # remote.origin.url=git@ssh.dev.azure.com:v3/<organisation>/<project>/<repository>
    # After
    # remote.origin.url=https://dev.azure.com/<organisation>/<project>/_git/<repository>
    echo "${remote_url}" | sed -re "s|git@ssh.dev.azure.com:v3/([^/]+)/([^/]+)/([^/]+)|https://dev.azure.com/\1/\2/_git/\3|g"
  elif [ "${mode}" = "https-to-ssh" ]; then
    # Before
    # remote.origin.url=https://dev.azure.com/<organisation>/<project>/_git/<repository>
    # After
    # remote.origin.url=git@ssh.dev.azure.com:v3/<organisation>/<project>/<repository>
    echo "${remote_url}" | sed -re "s|https://dev.azure.com/([^/]+)/([^/]+)/_git/([^/]+)|git@ssh.dev.azure.com:v3/\1/\2/\3|g"
  fi
}

update_remote_url() {
  local mode=$1
  local path=$2

  local remote_url
  remote_url=$(get_remote_url "${path}")

  local new_remote_url
  new_remote_url=$(get_new_remote_url "${mode}" "${remote_url}")

  echo -e "Old remote url: ${remote_url}"
  echo -e "New remote url: ${new_remote_url}"

  # Update git config only if both URLs are different
  if [ "${remote_url}" != "${new_remote_url}" ]; then
    echo -e "Remove old remote url."
    git -C "${path}" config --local --unset-all remote.origin.url
    echo -e "Update with new remote url."
    git -C "${path}" config --local --add remote.origin.url "${new_remote_url}"

    # Update submodules remote URL
    git -C "${path}" submodule sync
  fi
}

update_all_remote_url() {
  local mode=$1
  local directory=$2

  local sub_directories
  sub_directories=($(get_directories "${directory}"))

  echo -e "Sub directories: ${#sub_directories[@]}\n"

  for sub_directory in "${sub_directories[@]}"; do
    if [ "$(has_git_dir "${sub_directory}")" = "true" ]; then
      echo -e "\n${sub_directory}"

      # Update remote URL
      update_remote_url "${mode}" "${sub_directory}"
    fi
  done
}

show_help() {
  echo -e "Update all Git repositories remote URLs.\n"
  echo -e "${SCRIPT_NAME} <mode> [starting_directory]\n"
  echo -e "<mode> : https-to-ssh | ssh-to-https"
  echo -e "[starting_directory] : Find all git directories from this starting directoy to update remote URLs."
  exit 1
}

####################################################

# Handle parameters
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  show_help
fi

# Handle mode
if [ "$1" = "" ]; then
  echo -e "Mode is mandatory."
  show_help
elif [ "$1" != "https-to-ssh" ] && [ "$1" != "ssh-to-https" ]; then
  echo -e "Unknown mode ${mode}."
  show_help
else
  mode="$1"
  echo -e "Mode selected: ${mode}\n"
fi

# Handle starting directory
if [ "$2" = "" ]; then
  echo -e "No starting directory specified.\n"

  if [ "${WORKSPACES}" = "" ]; then
    echo -e "Please specify a starting directory or define a WORKSPACES environment variable.\n"
    show_help
  else
    start_dir="${WORKSPACES}"
  fi
else
  start_dir="$1"
  if [ ! -d "${start_dir}" ]; then
    echo -e "${start_dir} is not a directory."
    exit 1
  fi
fi

echo -e "Use ${start_dir} as starting directory.\n"

update_all_remote_url "${mode}" "${start_dir}"
