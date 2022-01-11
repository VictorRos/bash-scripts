#!/usr/bin/env bash

# Vérification du nombre d'arguments
if [ $# -eq 1 ]; then
  # Récupération de l'ID du container docker qui nous intéresse
  CONTAINER_ID=`bash ~/scripts/get-container-id.sh $1`

  if [ -z $CONTAINER_ID ]; then
    # Aucun container correspondant à l'argument
    echo -e "Aucun container correspondant à '$1' n'a été trouvé."
  else
    # Connexion au container docker
    docker exec -u root -it $CONTAINER_ID /bin/sh
  fi
else
  echo -e "Comment ça marche ?"
  echo -e "$0 <container_name>"
fi
