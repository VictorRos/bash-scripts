#!/usr/bin/env bash

# Créé les liens symboliques de tous les fichiers .sh disposés dans le même dossier que celui-ci
ls [^_]*.sh | awk '
  BEGIN { FS=" " }
  {
    gsub(/\.sh$/, "", $1) ;
    LINK_PATH="/usr/local/bin/" $1 ;
    print "Suppression de " LINK_PATH " ...";
    system("rm " LINK_PATH) ;
  }
  END { print "Liens symboliques supprimés" }
  '
