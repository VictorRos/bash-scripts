#!/bin/bash

# !!! WARNING : READ THIS !!!
# YOU MUST BE ADMIN USERS OR GLOBAL ADMIN TO RUN THIS SCRIPT

set -e # Exit on any error

# Constants
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)
# Folder to store files during functions' executions
AZ_AD_GROUPS_DIR="${SCRIPT_DIR}/../tmp/${SCRIPT_NAME}/az_ad_groups"
# Folder to store CSV generated files
CSV_DIR="${SCRIPT_DIR}/../tmp/${SCRIPT_NAME}/csv"
# Loop Azure AD Groups
AZURE_AD_GROUPS=(
  "GRP-LOOP-DEV-OWNERS"
  "GRP-LOOP-DEV-CONTRIBUTORS"
  "GRP-LOOP-MANAGER"
  "GRP-LOOP-PO-PM"
  "GRP-LOOP-LEAD-DEV"
  "GRP-LOOP-DEV"
  "GRP-LOOP-BIGDATA"
  "GRP-LOOP-QA"
  "GRP-LOOP-MODELISATION"
  "GRP-LOOP-DOC"
)

source "${SCRIPT_DIR}/../library/nv_library.sh"

# Global variables
tenants=()
domains=()
password=""
offline=false
create_admins=false

# Handle parameters
handle_parameters() {
  local tenants_tmp=()
  local domains_tmp=()
  local ARGS=()

  while [ $# -gt 0 ]; do
    unset OPTIND
    unset OPTARG

    while getopts ht:d:p:ao options; do
      case ${options} in
        # tenants
        t)
          IFS="," read -r -a tenants_tmp <<< "${OPTARG}"
          ;;
        # domains
        d)
          IFS="," read -r -a domains_tmp <<< "${OPTARG}"
          ;;
        # password
        p)
          password="${OPTARG}"
          ;;
        # To create admins account
        a)
          create_admins=true
          ;;
        # Offline mode to generate CSV files from generated JSON files (requests a first run in online mode)
        o)
          offline=true
          ;;
        # Show help
        h)
          show_help
          ;;
        *)
          echo -e "\n${YELLOW}Unsupported option ${OPTARG}${NO_COLOR}"
          exit 1
          ;;
      esac
    done
    shift $((OPTIND - 1))
    # Avoid adding an empty arg
    if [ "$1" != "" ]; then ARGS+=("$1"); fi
    # Avoid script to fail with no errors because we shift empty remaining args
    if [ $# -gt 0 ]; then shift; fi
  done

  # Stop if no tenants
  if [ ${#tenants_tmp[@]} -eq 0 ]; then
    error "Tenants are mandatory!"
    show_help
  # Stop if no domains and no admins creation
  elif [ ${#domains_tmp[@]} -eq 0 ] && [ "${create_admins}" = "false" ]; then
    error "Domains are mandatory!"
    show_help
  elif [ "${password}" = "" ]; then
    error "Password is mandatory!"
    show_help
  fi

  # Force lowercase
  for tenant in "${tenants_tmp[@]}"; do
    tenant=$(echo "${tenant}" | tr "[:upper:]" "[:lower:]")
    tenants+=("${tenant}")
  done
  for domain in "${domains_tmp[@]}"; do
    domain=$(echo "${domain}" | tr "[:upper:]" "[:lower:]")
    domains+=("${domain}")
  done

  # Create admins
  if [ "${create_admins}" = "true" ]; then
    info "Create admins users in Azure AD"
  fi

  # Offline/Online mode
  if [ "${offline}" = "true" ]; then
    info "Offline mode: Use users defined in JSON files from ${AZ_AD_GROUPS_DIR}"
  else
    info "Online mode: Get users from Azure AD"
  fi

  # Variables
  info "Tenants: ${#tenants[@]} (${tenants[*]})"
  info "Domains: ${#domains[@]} (${domains[*]})\n"
}

# Show Help
show_help() {
  echo -e "\nGenerate CSV files to create users in Azure AD for a tenant, and to create users in Loop applications.\n"
  echo -e "${RED}Mandatory options:${NO_COLOR}"
  echo -e "\t${RED}-t <tenants>: (example: -t tenant1,tenant2,tenant3)${NO_COLOR}"
  echo -e "\t${RED}-d <domains>: (example: -d domain1,domain2,domain3)${NO_COLOR}"
  echo -e "\t${RED}-p <password>: (example: -p \"MySup3rPa55w0rd!\")${NO_COLOR}"
  echo -e "${DEEP_SKY_BLUE}Optional options:${NO_COLOR}"
  echo -e "\t${DEEP_SKY_BLUE}-o : Offline mode to user users from generated JSON files when retrieving users.${NO_COLOR}"
  echo -e "\t${DEEP_SKY_BLUE}-a : Create a CSV file with admins tenant.${NO_COLOR}"
  echo -e "\t${DEEP_SKY_BLUE}-h : Show current help.${NO_COLOR}"
  exit 0
}

# Generates folders.
prepare() {
  echo -e "Generate folder ${AZ_AD_GROUPS_DIR}..."
  if [ ! -d "${AZ_AD_GROUPS_DIR}" ]; then
    mkdir -p "${AZ_AD_GROUPS_DIR}"
  fi
  echo -e "Generate folder ${CSV_DIR}..."
  if [ ! -d "${CSV_DIR}" ]; then
    mkdir -p "${CSV_DIR}"
  fi
}

# Remove tmp folder.
cleanup() {
  echo -e "Cleanup ${AZ_AD_GROUPS_DIR}..."
  rm -rf "${AZ_AD_GROUPS_DIR}"
}

# Generates a JSON file that contains all users from a Azure AD group.
# Note: Store results in JSON files using group names as filenames.
# Add profile 5.1 or 6.0 depending on Azure AD Group.
# <group> : Azure AD Group
# get_users_from_group <group>
get_users_from_group() {
  local profile=5.1
  local groupeDeTravail="[LOOP-DEFAUT]"

  # Users from GRP-LOOP-DEV-OWNERS will have profile 6.0 (super admin)
  if [ "$1" = "GRP-LOOP-DEV-OWNERS" ]; then
    profile=6.0
    groupeDeTravail="[LOOP-DEFAUT],[LOOP-GESTION-DES-DROITS]"
  fi

  az ad group member list --group "$1" --query '[].{
    userPrincipalName: userPrincipalName,
    mail: mail,
    givenName: givenName,
    surname: surname,
    usageLocation: usageLocation
  }' | jq 'map(
    .profile = "'"${profile}"'" |
    .groupeDeTravail = "'"${groupeDeTravail}"'"
  )' > "${AZ_AD_GROUPS_DIR}/$1.json"
}

# Generates JSON files for each Azure AD groups.
# Note: Store results in JSON files using group names as filenames.
# get_users_from_groups
get_users_from_groups() {
  for group in "${AZURE_AD_GROUPS[@]}"; do
    echo -e "Get users from group ${group}"
    get_users_from_group "${group}"
  done
}

# Get users from Azure AD groups.
# Note: Remove duplicates and add users from profil-users-template.json
# get_users
get_users() {
  # Merge all results & Remove duplicates
  cat "${AZ_AD_GROUPS_DIR}"/GRP-*.json "${SCRIPT_DIR}/profil-users-template.json" \
    | jq -s '[.[]] | flatten | sort_by(.userPrincipalName | ascii_downcase) | unique_by(.userPrincipalName)'
}

# Get admin users from "admin-users-template.json".
# get_admin_users
get_admin_users() {
  # Merge all results & Remove duplicates
  cat "${SCRIPT_DIR}/admin-users-template.json"
}

# Transform a Cegid UPN to a tenant UPN.
# Note: Tenant UPN includes domain.
# <users> : Users
# generate_upn_tenant <users>
generate_upn_tenant() {
  local users=$1

  # Generate properties that must be present for Azure AD Users creation
  echo "${users}" | jq 'map(
    .id = (.userPrincipalName | capture("(?<prefix>[^@]+)@.+") | .prefix + "-__DOMAIN__-__TENANT__") |
    .userPrincipalName = (.userPrincipalName | capture("(?<prefix>[^@]+)@.+") | .prefix + "-__DOMAIN__@__TENANT__.onmicrosoft.com")
  )'
}

# Add necessary properties to create users.
# <users> : Users
# add_users_properties <users>
add_users_properties() {
  local users=$1

  # Generate properties that must be present for Azure AD Users creation
  echo "${users}" | jq 'map(
    .mail = (.mail // .userPrincipalName) |
    .givenName = (.givenName // "Jon") |
    .surname = (.surname // "Snow" | ascii_upcase) |
    .displayName = .givenName + " " + .surname |
    .usageLocation = (.usageLocation // "IM") |
    .country = "FRANCE" |
    .profile = (.profile // "3.0") |
    .language = "français" |
    .actif = "true" |
    .telMobile = (.telMobile // "") |
    .telFixe = (.telFixe // "") |
    .roleOrga = (.roleOrga // "") |
    .groupeDeTravail = (.groupeDeTravail // "[LOOP-DEFAUT]")
  )'
}

# Add necessary properties to create users in Azure AD.
# <users> : Users
# add_azure_ad_users_properties <users>
add_azure_ad_users_properties() {
  local users=$1

  # Generate properties that must be present for Azure AD Users creation
  echo "${users}" | jq 'map(
    .passwordProfile = "'"${password}"'" |
    .accountEnabled = "TRUE"
  )'
}

# Consolidate data.
# <users> : Users
# <domain> : Domain | "ADMINS"
# consolidate_data <users> <domain>
consolidate_data() {
  local users=$1
  local domain=$2

  # For admins, we do not override UPN
  if [ "${domain}" != "ADMINS" ]; then
    users=$(generate_upn_tenant "${users}")
  fi
  users=$(add_users_properties "${users}")
  users=$(add_azure_ad_users_properties "${users}")

  echo "${users}"
}

# Filter users 'collaborateurs'.
# Without profiles 1.0, 2.0 and 2.5
# <users> : Users
# filter_collaborateur <users>
filter_collaborateur() {
  local users=$1

  echo "${users}" | jq 'map(
    select(.profile | (contains("1.0") or contains("2.0") or contains("2.5")) | not)
  )'
}

# Filter users 'interlocuteur'.
# Only profiles 1.0, 2.0 and 2.5
# <users> : Users
# filter_interlocuteur <users>
filter_interlocuteur() {
  local users=$1

  echo "${users}" | jq 'map(
    select(.profile | (contains("1.0") or contains("2.0") or contains("2.5")))
  )'
}

# Generates a CSV file for Azure AD users creation.
# <users> : Users (JSON format)
# <tenant> : Tenant
# <domain> : Domain | "ADMINS"
# generate_csv_azure_ad_insert <users> <tenant> <domain>
generate_csv_azure_ad_insert() {
  local users=$1
  local tenant=$2
  local domain=$3

  local domain_upper
  domain_upper=$(echo "${domain}" | tr "[:lower:]" "[:upper:]")
  local filename="az-ad-insert-${domain_upper}-${tenant}.csv"

  echo -e "Generate CSV for tenant ${tenant} with domain ${domain} (${filename})"

  users=$(consolidate_data "${users}" "${domain}")

  # Add "version:v1.0" as headers (Microsoft throws an error if this line is not present)
  echo "version:v1.0" > "${CSV_DIR}/${filename}"

  # Add CSV headers
  echo "Name [displayName] Required,User name [userPrincipalName] Required,Initial password [passwordProfile] Required,Block sign in (Yes/No) [accountEnabled] Required,First name [givenName],Last name [surname],Usage location [usageLocation]" >> "${CSV_DIR}/${filename}"

  # Add CSV lines
  echo "${users}" | jq -r '["displayName","userPrincipalName","passwordProfile","accountEnabled","givenName","surname","usageLocation"] as $headers | map([.[ $headers[] ]])[] | @csv' >> "${CSV_DIR}/${filename}"

  # Replace placeholders
  sed -i "" "s/__DOMAIN__/${domain}/g" "${CSV_DIR}/${filename}"
  sed -i "" "s/__DOMAIN_UPPER__/${domain_upper}/g" "${CSV_DIR}/${filename}"
  sed -i "" "s/__TENANT__/${tenant}/g" "${CSV_DIR}/${filename}"
}

# Generates a CSV file for Azure AD users removals.
# <users> : Users (JSON format)
# <tenant> : Tenant
# <domain> : Domain | "ADMINS"
# generate_csv_azure_ad_delete <users> <tenant> <domain>
generate_csv_azure_ad_delete() {
  local users=$1
  local tenant=$2
  local domain=$3

  local domain_upper
  domain_upper=$(echo "${domain}" | tr "[:lower:]" "[:upper:]")
  local filename="az-ad-delete-${domain_upper}-${tenant}.csv"

  echo -e "Generate CSV for tenant ${tenant} with domain ${domain} (${filename})"

  users=$(consolidate_data "${users}" "${domain}")

  # Add "version:v1.0" as headers (Microsoft throws an error if this line is not present)
  echo "version:v1.0" > "${CSV_DIR}/${filename}"

  # Add CSV headers
  echo "User name [userPrincipalName] Required" >> "${CSV_DIR}/${filename}"

  # Add CSV lines
  echo "${users}" | jq -r '["userPrincipalName"] as $headers | map([.[ $headers[] ]])[] | @csv' >> "${CSV_DIR}/${filename}"

  # Replace placeholders
  sed -i "" "s/__DOMAIN__/${domain}/g" "${CSV_DIR}/${filename}"
  sed -i "" "s/__DOMAIN_UPPER__/${domain_upper}/g" "${CSV_DIR}/${filename}"
  sed -i "" "s/__TENANT__/${tenant}/g" "${CSV_DIR}/${filename}"
}

# Generates a TSV file to add users "collaborateur" in Loop.
# Without profiles 1.0, 2.0 and 2.5
# <users> : Users (JSON format)
# <tenant> : Tenant
# <domain> : Domain
# generate_tsv_app_loop_collaborateur <users> <tenant> <domain>
generate_tsv_app_loop_collaborateur() {
  local users=$1
  local tenant=$2
  local domain=$3

  local domain_upper
  domain_upper=$(echo "${domain}" | tr "[:lower:]" "[:upper:]")
  local filename="loop-users-collaborateur-${domain_upper}.tsv"

  echo -e "Generate TSV file to add users 'collaborateur' in Loop (${filename})"

  users=$(filter_collaborateur "${users}")
  users=$(consolidate_data "${users}" "${domain}")

  # Add TSV headers
  echo -e "identifiant\tprenom\tnom\temail\tlogin\tadresse_pays\tlangue\tactif\tprofile\tgroupeDeTravail\tsignature_emailSignature" > "${CSV_DIR}/${filename}"

  # Add TSV lines
  echo "${users}" | jq -r '["id","givenName","surname","mail","userPrincipalName","country","language","actif","profile","groupeDeTravail","mail"] as $headers | map([.[ $headers[] ]])[] | @tsv' >> "${CSV_DIR}/${filename}"

  # Replace placeholders
  sed -i "" "s/__DOMAIN__/${domain}/g" "${CSV_DIR}/${filename}"
  sed -i "" "s/__DOMAIN_UPPER__/${domain_upper}/g" "${CSV_DIR}/${filename}"
  sed -i "" "s/__TENANT__/${tenant}/g" "${CSV_DIR}/${filename}"
}

# Generates a TSV file to add users "interlocuteur" in Loop.
# Only profiles 1.0, 2.0 and 2.5
# <users> : Users (JSON format)
# <tenant> : Tenant
# <domain> : Domain
# generate_tsv_app_loop_interlocuteur <users> <tenant> <domain>
generate_tsv_app_loop_interlocuteur() {
  local users=$1
  local tenant=$2
  local domain=$3

  local domain_upper
  domain_upper=$(echo "${domain}" | tr "[:lower:]" "[:upper:]")
  local filename="loop-users-interlocuteur-${domain_upper}.tsv"

  echo -e "Generate TSV file to add users 'interlocuteur' in Loop (${filename})"

  users=$(filter_interlocuteur "${users}")
  users=$(consolidate_data "${users}" "${domain}")

  # Add TSV headers
  echo -e "nom\tprenom\ttelMobile\ttelFixe\temail\troleOrga\tprofile\tadresse_pays\tactif" > "${CSV_DIR}/${filename}"

  # Add TSV lines
  echo "${users}" | jq -r '["surname","givenName","telMobile","telFixe","mail","roleOrga","profile","country","actif"] as $headers | map([.[ $headers[] ]])[] | @tsv' >> "${CSV_DIR}/${filename}"

  # Replace placeholders
  sed -i "" "s/__DOMAIN__/${domain}/g" "${CSV_DIR}/${filename}"
  sed -i "" "s/__DOMAIN_UPPER__/${domain_upper}/g" "${CSV_DIR}/${filename}"
  sed -i "" "s/__TENANT__/${tenant}/g" "${CSV_DIR}/${filename}"
}

# Main method
main() {
  handle_parameters "$@"

  prepare

  # In offline mode, use downloaded JSON files for users (script must be run in online mode at least once)
  if [ "${offline}" = "false" ]; then
    get_users_from_groups
  fi

  # 1 - Get users
  # 1.1 - Get admin users from JSON template file
  local admins
  if [ "${create_admins}" = "true" ]; then
    admins=$(get_admin_users)
    echo "${admins}" > "${AZ_AD_GROUPS_DIR}/users_azure_ad.json"
  fi
  # 1.2 - Get users from Azure AD groups and add profil users from JSON template file
  local users
  users=$(get_users)
  echo "${users}" >> "${AZ_AD_GROUPS_DIR}/users_azure_ad.json"

  # 2 - For each tenant, build CSV file
  for tenant in "${tenants[@]}"; do
    # Log in to tenant
    # az login --tenant "${tenant}.onmicrosoft.com" --allow-no-subscriptions

    # 2.1 - Generate CSV file for admin users
    if [ "${create_admins}" = "true" ]; then
      generate_csv_azure_ad_insert "${admins}" "${tenant}" "ADMINS"
      generate_csv_azure_ad_delete "${admins}" "${tenant}" "ADMINS"
    fi
    # 2.2 - Generate CSV files for users
    for domain in "${domains[@]}"; do
      generate_csv_azure_ad_insert "${users}" "${tenant}" "${domain}"
      generate_csv_azure_ad_delete "${users}" "${tenant}" "${domain}"
      generate_tsv_app_loop_collaborateur "${users}" "${tenant}" "${domain}"
      generate_tsv_app_loop_interlocuteur "${users}" "${tenant}" "${domain}"
    done
  done

  # cleanup
}

main "$@"
