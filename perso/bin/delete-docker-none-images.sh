#!/usr/bin/env bash

echo -e "Suppression des images docker <none> ...\n"
docker rmi $(docker images -f "dangling=true" -q)
echo -e "\nSuppression terminée"
