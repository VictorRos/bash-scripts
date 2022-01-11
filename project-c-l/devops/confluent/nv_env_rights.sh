#!/bin/bash

# Add the right cluster admin of all these email to all cluster with name begin "dev-loop"

set -e

emails=(
  "abindlish@cegid.com"
  "ageorges@cegid.com"
  "aledilhuit@cegid.com"
  "byeghiazarian@cegid.com"
  "cchabot@cegid.com"
  "cmalie@cegid.com"
  "cshen@cegid.com"
  "ddevial@cegid.com"
  "dfibleuil@cegidgroup.onmicrosoft.com"
  "gcheylac@cegid.com"
  "gdangel@cegid.com"
  "jagahunia@cegid.com"
  "jmailley@cegid.com"
  "jmaison@cegid.com"
  "jpasteris@cegid.com"
  "jspelerin@cegid.com"
  "lcella@cegid.com"
  "lportales@cegid.com"
  "lthompson@cegid.com"
  "mmohamed@cegid.com"
  "mpechtimaldjian@cegid.com"
  "mrankin@cegid.com"
  "mtauzin@cegid.fr"
  "mtighidet@cegid.com"
  "mvandecasteele@cegid.com"
  "mvialette@cegid.com"
  "nratiarimananjatovo@cegid.com"
  "ojohnstone@cegid.com"
  "okaloidas@cegid.com"
  "pcrispim@cegid.com"
  "pphileston@cegid.com"
  "rdiana@cegid.com"
  "rjyala@cegid.com"
  "rvolkov@cegid.com"
  "slupu@cegid.com"
  "souk@cegid.com"
  "spavat@cegid.com"
  "stboussert@cegid.com"
  "tbaudis@cegid.com"
  "tmartins@cegid.com"
  "zkun@cegid.com"
)

echo -e "Nb emails: ${#emails[@]}"

# Specify the env/cluster. The list on the top are almost all dev env

devLoopEnv=$(confluent environment list -o json | jq '[ .[] | select(.name | test("dev-loop")) ]')
envIds=($(echo "${devLoopEnv}" | jq -r '.[].id'))
envNames=($(echo "${devLoopEnv}" | jq -r '.[].name'))
adminUserList=$(confluent iam user list -o json)

for ((i = 0; i < ${#emails[@]}; i++)); do
  email=${emails[$i]}
  echo -e "Email: ${email}"

  userId=$(echo "${adminUserList}" | jq -r '.[] | select(.email | test("'"${email}"'")) | .id')
  echo -e "User Id: ${userId}"

  if [ -n "${userId}" ]; then
    for ((j = 0; j < ${#envNames[@]}; j++)); do
      envId=${envIds[$j]}
      envName=${envNames[$j]}
      echo -e "\n  Env ${envName}: ${envId}"

      echo confluent iam rbac role-binding create --principal "User:${userId}" --role EnvironmentAdmin --environment "${envId}"
      # confluent iam rolebinding create --principal "User:${userId}" --role EnvironmentAdmin --environment "${envId}"
      confluent iam rbac role-binding create --principal "User:${userId}" --role EnvironmentAdmin --environment "${envId}"
    done
  fi
done
