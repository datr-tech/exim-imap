#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

#####################################################################
#                                                                   #
# Script:  generate_dovecot_sql_conf.sh                             #
#                                                                   #
# Purpose: Generate 'dovecot-sql.conf' from from the associated     #
#          template file, dovecot-sql.conf.TEMPLATE.with env var    #
#          values.                                                  #
#                                                                   #
# Date:    13th May 2025                                            #
# Author:  datr.tech admin <admin@datr.tech>                        #
#                                                                   #
#####################################################################

#####################################################################
#                                                                   #
# MAIN SECTIONS (within the code below)                             #
# =====================================                             #
#                                                                   #
# 1.  DEFINITIONS                                                   #
# 2.  CHECK DEPENDENCIES                                            #
# 3.  DIR AND FILE PATHS                                            #
# 4.  LOAD AND CHECK ENV VARS                                       #
# 5.  CREATE OUT_FILE                                               #
# 6.  MODIFY OUT_FILE                                               #
#                                                                   #
#####################################################################

#####################################################################
#####################################################################
#                                                                   #
#                                                                   #
# 1. DEFINITIONS                                                    #
#                                                                   #
#                                                                   #
#####################################################################
#####################################################################

#####################################################################
#                                                                   #
# 1.1  Primary file names                                           #
#                                                                   #
#####################################################################

declare -r IN_FILE_NAME="dovecot-sql.conf.TEMPLATE"
declare -r OUT_FILE_NAME="dovecot-sql.conf"

#####################################################################
#                                                                   #
# 1.2  Secondary file and dir names                                 #
#                                                                   #
#####################################################################

declare -r ENV_FILE_NAME=".env"
declare -r CONF_DIR_NAME="conf"
declare -r SCRIPTS_DIR_NAME="scripts"

#####################################################################
#                                                                   #
# 1.3  Required env vars                                            #
#                                                                   #
#####################################################################

declare -a -r REQUIRED_ENV_VARS=(
  "EXIM_IMAP__DATABASE__NAME"
  "EXIM_IMAP__DATABASE__USER_NAME"
  "EXIM_IMAP__DATABASE__USER_PASS"
  "EXIM_IMAP__TEMPLATE_FILE__VARIABLE_PREFIX_TAG"
)

#####################################################################
#                                                                   #
# 1.4  Required dependencies (for the current file)                 #
#                                                                   #
#####################################################################

declare -a -r REQUIRED_DEPENDENCIES=("sed")

#####################################################################
#####################################################################
#                                                                   #
#                                                                   #
# 2. CHECK DEPENDENCIES                                             #
#                                                                   #
#                                                                   #
#####################################################################
#####################################################################

#####################################################################
#                                                                   #
# 2.1  Check the required dependencies (for the current file)       #
#                                                                   #
#####################################################################

declare required_dependency

for required_dependency in "${REQUIRED_DEPENDENCIES[@]}"; do
  if ! command -v "${required_dependency}" > /dev/null 2>&1; then
    echo "${required_dependency}: not found" >&2
    exit 1
  fi
done

#####################################################################
#####################################################################
#                                                                   #
#                                                                   #
# 3. DIR AND FILE PATHS                                             #
#                                                                   #
#                                                                   #
#####################################################################
#####################################################################

#####################################################################
#                                                                   #
# 3.1  Dir paths                                                    #
#                                                                   #
#####################################################################

SCRIPTS_DIR_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
readonly SCRIPTS_DIR_PATH

ROOT_DIR_PATH="${SCRIPTS_DIR_PATH/\/${SCRIPTS_DIR_NAME}/}"
readonly ROOT_DIR_PATH

CONF_DIR_PATH="${ROOT_DIR_PATH}/${CONF_DIR_NAME}"
readonly CONF_DIR_PATH

#####################################################################
#                                                                   #
# 3.2  File paths                                                   #
#                                                                   #
#####################################################################

ENV_FILE_PATH="${ROOT_DIR_PATH}/${ENV_FILE_NAME}"
readonly ENV_FILE_PATH

IN_FILE_PATH="${CONF_DIR_PATH}/${IN_FILE_NAME}"
readonly IN_FILE_PATH

OUT_FILE_PATH="${CONF_DIR_PATH}/${OUT_FILE_NAME}"
readonly OUT_FILE_PATH

#####################################################################
#                                                                   #
# 3.3  Check ENV_FILE_PATH                                          #
#                                                                   #
#####################################################################

#shellcheck source=/.env
if [ ! -s "${ENV_FILE_PATH}" ]; then
  echo "ENV_FILE_PATH: invalid"
  exit 1
fi

#####################################################################
#                                                                   #
# 3.4  Check IN_FILE_PATH                                           #
#                                                                   #
#####################################################################

#shellcheck source=/sql/exim_db.sql.b64
if [ ! -s "${IN_FILE_PATH}" ]; then
  echo "IN_FILE_PATH: invalid"
  exit 1
fi

#####################################################################
#####################################################################
#                                                                   #
#                                                                   #
# 4. LOAD AND CHECK ENV VARS                                        #
#                                                                   #
#                                                                   #
#####################################################################
#####################################################################

#####################################################################
#                                                                   #
# 4.1  Load env vars                                                #
#                                                                   #
#####################################################################

set -a
# shellcheck source=/.env
source "${ENV_FILE_PATH}"
set +a

#####################################################################
#                                                                   #
# 4.2  Check the required env vars                                  #
#                                                                   #
#####################################################################

declare required_env_var

for required_env_var in "${REQUIRED_ENV_VARS[@]}"; do
  if [ -z "${!required_env_var}" ]; then
    echo "${required_env_var}: not found" >&2
    exit 1
  fi
done

#####################################################################
#####################################################################
#                                                                   #
#                                                                   #
# 5.  CREATE OUT_FILE                                               #
#                                                                   #
#                                                                   #
#####################################################################
#####################################################################

#####################################################################
#                                                                   #
# 5.1  Back up OUT_FILE (if it exists)                              #
#                                                                   #
#####################################################################

if [ -f "${OUT_FILE_PATH}" ]; then
  timestamp=$(date +%s)
  readonly timestamp

  mv "${OUT_FILE_PATH}" "${OUT_FILE_PATH}.${timestamp}.bak"
fi

#####################################################################
#                                                                   #
# 5.2  Copy IN_FILE to OUT_FILE                                     #
#                                                                   #
#####################################################################

cp "${IN_FILE_PATH}" "${OUT_FILE_PATH}"

#####################################################################
#####################################################################
#                                                                   #
#                                                                   #
# 6.  MODIFY OUT_FILE                                               #
#                                                                   #
#                                                                   #
#####################################################################
#####################################################################

declare required_var
declare sed_body
declare template_var
declare template_value

for required_var in "${REQUIRED_ENV_VARS[@]}"; do
  template_var="${EXIM_IMAP__TEMPLATE_FILE__VARIABLE_PREFIX_TAG}${required_var}"
  template_value="${!required_var}"

  sed_body="s/${template_var}/${template_value}/g"
  sed -i "${sed_body}" "${OUT_FILE_PATH}"
done
