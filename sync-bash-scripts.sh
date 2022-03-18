#!/usr/bin/env bash

SOURCE_REPO_DEVOPS="${HOME}/workspaces/workspace-devops/Loop-DevOps/scripts/sh"
SOURCE_REPO_CHARTS="${HOME}/workspaces/workspace-devops/charts/.pipelines/scripts"

TARGET_REPO="${HOME}/workspaces/workspace-perso/bash-scripts"
TARGET_REPO_PROJECT_C_L="${TARGET_REPO}/project-c-l"

copy_files_project_c_l() {
  if [ -d "${SOURCE_REPO_DEVOPS}/devops" ] || \
    [ -d "${SOURCE_REPO_DEVOPS}/pipeline" ] || \
    [ -d "${SOURCE_REPO_CHARTS}" ] || \
    [ -e "${HOME}/addin-bashrc" ] || \
    [ -e "${HOME}/addin-zshrc" ]; then

    echo "Sync Project C L"

    # Copy DevOps scripts
    if [ -d "${SOURCE_REPO_DEVOPS}/devops" ] || [ -d "${SOURCE_REPO_DEVOPS}/pipeline" ]; then
      echo "  Sync DevOps"

      if [ -d "${SOURCE_REPO_DEVOPS}/devops" ]; then
        mkdir -p "${TARGET_REPO_PROJECT_C_L}/devops"
        cp -R "${SOURCE_REPO_DEVOPS}/devops/." "${TARGET_REPO_PROJECT_C_L}/devops"
        # Remove folder tmp
        rm -rf "${TARGET_REPO_PROJECT_C_L}/devops/tmp"
      fi
      if [ -d "${SOURCE_REPO_DEVOPS}/pipeline" ]; then
        mkdir -p "${TARGET_REPO_PROJECT_C_L}/pipeline"
        cp -R "${SOURCE_REPO_DEVOPS}/pipeline/." "${TARGET_REPO_PROJECT_C_L}/pipeline"
      fi
    fi

    # Copy charts scripts
    if [ -d "${SOURCE_REPO_CHARTS}" ]; then
      echo "  Sync Helm charts"
      mkdir -p "${TARGET_REPO_PROJECT_C_L}/helm"
      cp -R "${SOURCE_REPO_CHARTS}/." "${TARGET_REPO_PROJECT_C_L}/helm"
    fi

    if [ -e "${HOME}/addin-bashrc" ]; then
      echo "  Sync addin-bashrc"
      cp -R "${HOME}/addin-bashrc" "${TARGET_REPO_PROJECT_C_L}"
    fi
    if [ -e "${HOME}/addin-zshrc" ]; then
      echo "  Sync addin-zshrc"
      cp -R "${HOME}/addin-zshrc" "${TARGET_REPO_PROJECT_C_L}"
    fi
  fi
}

commit_changes() {
  git -C "${TARGET_REPO}" add -A
  git -C "${TARGET_REPO}" commit -m "Sync bash scripts at $(date "+%Y-%m-%d %H:%M:%S")"
  git -C "${TARGET_REPO}" push
}

sync_bash_scripts() {
  copy_files_project_c_l
  commit_changes
}

sync_bash_scripts
