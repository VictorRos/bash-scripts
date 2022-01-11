#!/usr/bin/env bash

# Vérification du nombre d'arguments
if [ $# -eq 2 ]; then
  PRIVATE_KEY=$1
  PUBLIC_KEY=$2
  diff <( ssh-keygen -y -e -f "$PRIVATE_KEY" ) <( ssh-keygen -y -e -f "$PUBLIC_KEY" )
else
  echo -e "Comment ça marche ?"
  echo -e "$0 <private_key> <public_key>"
  echo -e "\nTest une clé SSH privée avec une clé SSH publique pour valider qu'elles vont de pair."
fi

