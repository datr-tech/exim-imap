#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

#####################################################################
#                                                                   #
#                                                                   #
# Script:  generate_conf_template.sh                                #
#                                                                   #
#                                                                   #
# Purpose: Generate a clean .TEMPLATE file from the                 #
#          received config file path.                               #
#                                                                   #
#                                                                   #
# Date:    12th May 2025                                            #
# Author:  datr.tech admin <admin@datr.tech>                        #
#                                                                   #
#                                                                   #
#####################################################################

#####################################################################
#                                                                   #
#                                                                   #
# SECTIONS (within the code below)                                  #
# ================================                                  #
#                                                                   #
#                                                                   #
# 1. DEFINITIONS                                                    #
# --------------                                                    #
#                                                                   #
# 1.1   Primary file names                                          #
# 1.2   Secondary file and dir names                                #
# 1.3   Required dependencies (for the current file)                #
#                                                                   #
#                                                                   #
# 2. CHECK DEPENDENCIES                                             #
# ---------------------                                             #
#                                                                   #
# 2.1   Check required dependencies (for the current file)          #
#                                                                   #
#                                                                   #
# 3. DIR AND FILE PATHS                                             #
# ---------------------                                             #
#                                                                   #
# 3.1   Dir paths                                                   #
# 3.2   File paths                                                  #
# 3.3   Check IN_FILE_PATH                                          #
#                                                                   #
#                                                                   #
# 4. GENERATE OUT_FILE (.env.TEMPLATE)                              #
# ------------------------------------                              #
#                                                                   #
# 4.1  Back up OUT_FILE (if it exists)                              #
# 4.2  Generate OUT_FILE from IN_FILE                               #
#                                                                   #
#####################################################################

#####################################################################
#                                                                   #
# 1.1  Primary file names                                           #
#                                                                   #
#####################################################################

declare -r IN_FILE_NAME=${1}
declare -r OUT_FILE_NAME="${IN_FILE_NAME}.TEMPLATE"

#####################################################################
#                                                                   #
# 1.2  Secondary file and dir names                                 #
#                                                                   #
#####################################################################

declare -r SCRIPTS_DIR_NAME="scripts"

#####################################################################
#                                                                   #
# 1.3  Required dependencies (for the current file)                 #
#                                                                   #
#####################################################################

declare -a -r REQUIRED_DEPENDENCIES=(
  "dirname"
  "sed"
)

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

#####################################################################
#                                                                   #
# 3.2  File paths                                                   #
#                                                                   #
#####################################################################

IN_FILE_PATH="${ROOT_DIR_PATH}/${IN_FILE_NAME}"
readonly IN_FILE_PATH

OUT_FILE_PATH="${ROOT_DIR_PATH}/${OUT_FILE_NAME}"
readonly OUT_FILE_PATH

#####################################################################
#                                                                   #
# 3.3  Check IN_FILE_PATH                                           #
#                                                                   #
#####################################################################

#shellcheck source=.env
if [ ! -s "${IN_FILE_PATH}" ]; then
  echo "IN_FILE_PATH: invalid"
  exit 1
fi

#####################################################################
#####################################################################
#                                                                   #
#                                                                   #
# 4. GENERATE OUT_FILE (.env.TEMPLATE)                              #
#                                                                   #
#                                                                   #
#####################################################################
#####################################################################

#####################################################################
#                                                                   #
# 4.1  Back up OUT_FILE (if it exists)                              #
#                                                                   #
#####################################################################

if [ -f "${OUT_FILE_PATH}" ]; then
  timestamp=$(date +%s)
  readonly timestamp

  mv "${OUT_FILE_PATH}" "${OUT_FILE_PATH}.${timestamp}.bak"
fi

#####################################################################
#                                                                   #
# 4.2  Generate OUT_FILE from IN_FILE                               #
#                                                                   #
#####################################################################

#
# Convert IN_FILE env vars string values to "" (within the OUT_FILE)
#
sed -E 's/\".+\"/\"\"/g' "${IN_FILE_PATH}" > "${OUT_FILE_PATH}"

#
# Convert (in place) env vars numeric values to 0
#
sed -E -i 's/=[0-9]+/=0/g' "${OUT_FILE_PATH}"

#
# Convert (in place) env vars bool values to the key phrase '<BOOL_VALUE>'
#
sed -E -i "s/=(true|false)/='<BOOL_VALUE>'/g" "${OUT_FILE_PATH}"
