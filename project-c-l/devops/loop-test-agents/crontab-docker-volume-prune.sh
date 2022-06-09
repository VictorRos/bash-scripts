#!/usr/bin/env bash

LOG_FILE="crontab.log"

NB_IMAGES=$(docker volume ls -q | wc -l)

# Remove docker volumes
docker volume prune -f

# Add log
CURRENT_DATE=$(date +"%Y-%m-%d %H:%M:%S")
echo "${CURRENT_DATE} Remove ${NB_IMAGES} docker volume·s" >> ${LOG_FILE}
