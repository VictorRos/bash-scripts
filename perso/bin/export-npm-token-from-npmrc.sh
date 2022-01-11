#!/usr/bin/env bash

# Exporte le Token NPM du registre "all-npm" (fait lors du "npm login" à "all-npm")
export NPM_TOKEN=$(cat ~/.npmrc | grep //cegid.jfrog.io/cegid/api/npm/all-npm/:_authToken= | cut -d "=" -f2)
echo "NPM_TOKEN=${NPM_TOKEN}"
