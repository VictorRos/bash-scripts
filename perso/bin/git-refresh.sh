#!/usr/bin/env bash

# Le script fonctionne pour les arborescences suivantes

# Arborescence à plusieurs workspaces
#
# WORKSPACES
# |-- workspace-compta
#     |-- arpege-web
#     |-- GI
#     |-- tools
#     |-- Yupana-Framework
#     |-- ...
# |-- workspace-npm
#     |-- Loop-NPM-Logger
#     |-- ...
# |-- workspace-devops
#     |-- Loop-DevOps
#     |-- charts
#     |-- ...
# |-- ...
#
# NOTE : Tous les répertoires des workspaces doivent commencer par "workspace-*"

# Arborescence mono workspace
#
# WORKSPACES
# |-- arpege-web
# |-- GI
# |-- tools
# |-- Yupana-Framework
# |-- Loop-NPM-Logger
# |-- Loop-DevOps
# |-- charts
# |-- ...

update_remote() {
  git -C $1 fetch --all --prune --prune-tags --tags --force
}

delete_all_local_branches_not_on_remote() {
  git -C $1 branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git -C $1 branch -vv | grep origin) | awk '{print $1}' | xargs git -C $1 branch -D
}

is_current_branch_gone() {
  git -C $1 branch -vv | { grep "^\*" || true; } | { grep ": gone]" || true; } | awk '{print $2}'
}

directoryRefPath=${WORKSPACES}
if [ -z "${directoryRefPath}" ]; then
  echo -e "\nLa variable d'environnement WORKSPACES n'existe pas."
  echo -e "Utilise le répertoire courant comme référence."
  directoryRefPath=$(pwd)
fi
echo -e "\nRépertoire de référence : ${directoryRefPath}"

# Recherche tous les projets Git dans directoryRefPath sur une profondeur max de 4
gitProjectsPath=($(find ${directoryRefPath} -type d -path "*/.git" -maxdepth 4 | sort -u))

for gitProjectPath in "${gitProjectsPath[@]}" ; do
  projectPath=$(dirname ${gitProjectPath})
  projectFolder=$(basename ${projectPath})

  echo -e "\n**************************************************"
  echo -e "* REFRESH ${projectFolder}"
  echo -e "**************************************************\n"

  # Met à jour les branches distantes (nouvelles, supprimées) et les tags (nouveaux, supprimés)
  update_remote ${projectPath}

  # Si la branche courrante n'existe plus sur le repository distant, on switch sur master
  if [ "$(is_current_branch_gone ${projectPath})" != "" ]; then
    # Récupère la branche par défaut du repository distant
    defaultBranch=$(git -C ${projectPath} remote show origin | sed -n '/HEAD branch/s/.*: //p')

    echo "Git switch to branch ${defaultBranch}"
    git -C ${projectPath} switch "${defaultBranch}"
  fi

  # Supprime les branches locales qui n'ont plus de référence sur le repository distant
  delete_all_local_branches_not_on_remote ${projectPath}

  # Récupère les derniers commits de la branche courante
  git -C ${projectPath} pull --rebase
done
