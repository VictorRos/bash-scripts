#!/usr/bin/env bash

# Récupération de l'ID du container docker mssql
CONTAINER_ID=$(get-container-id mssql)

if [ -z ${CONTAINER_ID} ]; then
  # Aucun container correspondant à l'argument
  echo -e "Aucun container correspondant à '${CONTAINER_ID}' n'a été trouvé."
else
  # Connexion au container docker
  docker exec $CONTAINER_ID bash -c '
  cd /var/opt/mssql/data ;
  FILES_TO_MOVE_TO_BACKUPS=$(ls | grep -E "\.bak$") ;
  for fileToMove in $FILES_TO_MOVE_TO_BACKUPS; do echo "Move $fileToMove to /var/backups"; mv $fileToMove /var/backups; done ;
  '
fi
