#!/usr/bin/env bash

# Vérification du nombre d'arguments
if [ $# -eq 1 ]; then
  # Utilise l'argument pour filtrer les containers et retourne le premier résultat
  docker ps -a -q --filter "name=$1"
else
  echo -e "Comment ça marche ?"
  echo -e "$0 <container_name>"
  echo -e "\nRetourne le premier ID rencontré si l'argument utilisé pour filtrer les containers retournent plusieurs résultats."
fi
