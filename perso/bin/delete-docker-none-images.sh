#!/usr/bin/env bash

set -e # Exit on any error

DOCKER_CONTAINERS=$(docker container ls -aq)
if [ "${DOCKER_CONTAINERS}" != "" ]; then
  echo -e "Delete docker containers...\n"
  docker container rm -f "${DOCKER_CONTAINERS}"
  echo -e "\nDeletion finished!"
fi

DOCKER_IMAGES_DANGLING=$(docker images -f "dangling=true" -q)
if [ "${DOCKER_IMAGES_DANGLING}" != "" ]; then
  echo -e "Delete dangling docker images (<none>)...\n"
  docker rmi "$(docker images -f "dangling=true" -q)"
  echo -e "\nDeletion finished!"
fi
