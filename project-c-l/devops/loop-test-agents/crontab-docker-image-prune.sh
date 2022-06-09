#!/usr/bin/env bash

LOG_FILE="crontab.log"

NB_IMAGES=$(docker images -q | wc -l)

# Remove docker images
docker image prune -a -f

# Add log
CURRENT_DATE=$(date +"%Y-%m-%d %H:%M:%S")
echo "${CURRENT_DATE} Remove ${NB_IMAGES} docker image·s" >> ${LOG_FILE}
