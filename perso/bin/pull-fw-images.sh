#!/usr/bin/env bash

# Vérification du nombre d'arguments
if [ $# -eq 1 ]; then
  FRAMEWORK_VERSION=$1
  REPOSITORY_DOCKER=cegid-yupana-docker.jfrog.io/yupana
  # REPOSITORY_DOCKER=cegid-loop-docker.jfrog.io/timeline
  LOG_FILE=~/scripts/logs/$(basename $0)-$FRAMEWORK_VERSION.log

  # Create logs directory
  mkdir -p ~/scripts/logs

  docker pull $REPOSITORY_DOCKER/core:$FRAMEWORK_VERSION
  # docker pull $REPOSITORY_DOCKER/corewithaddon:$FRAMEWORK_VERSION
  docker pull $REPOSITORY_DOCKER/events-service:latest
  docker pull $REPOSITORY_DOCKER/framework:$FRAMEWORK_VERSION
  docker pull $REPOSITORY_DOCKER/serverfunction:$FRAMEWORK_VERSION
  docker pull $REPOSITORY_DOCKER/ydbdata:$FRAMEWORK_VERSION-direct
  docker pull $REPOSITORY_DOCKER/ydbutils:$FRAMEWORK_VERSION

  echo "Images docker $FRAMEWORK_VERSION mises à jour le $(date +"%d/%m/%Y à %T")" >> $LOG_FILE 2>&1
else
  echo -e "Comment ça marche ?"
  echo -e "$0 <framework_version>"
  echo -e "\nRécupère les images du framework de la version passée en paramètre (Par exemple : dev, weekly, 3.9.3, etc.)."
fi
