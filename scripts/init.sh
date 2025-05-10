#!/usr/bin/env bash

set -euo pipefail

######################################################################
#                                                                    #
# 1. COMMON VARS                                                     #
#                                                                    #
######################################################################

#
# DIR VARS
#
declare ROOT_DIR

ROOT_DIR="$(dirname "${BASH_SOURCE[0]}")/.."
declare -r LIB_DIR="${ROOT_DIR}/lib"

#
# REQUIRED SCRIPT DEPENDENCIES
#
declare REQUIRED_SCRIPT_DEPENDENCY
declare -a REQUIRED_SCRIPT_DEPENDENCIES=( "apt" "bash" "curl" "npm" )

#
# APT PKGS TO INSTALL
#
declare APT_PKG_TO_INSTALL
declare -a APT_PKGS_TO_INSTALL=( "shellcheck" "swaks" )

#
# NON APT PKG TO INSTALL VARS
#
declare -r NON_APT_PKG_BASHUNIT_NAME="bashunit"
declare -r NON_APT_PKG_BASHUNIT_PATH="${LIB_DIR}/${NON_APT_PKG_BASHUNIT_NAME}"
declare -r NON_APT_PKG_BASHUNIT_REPO_URL="https://bashunit.typeddevs.com/install.sh"
declare -r NON_APT_PKG_EDITORCONFIG_NAME="editorconfig-cli"
declare -r NON_APT_PKG_EDITORCONFIG_REPO_URL="@htmlacademy/${NON_APT_PKG_EDITORCONFIG_NAME}"

#
# ERROR MSGS
#
declare -r ERROR_MSG_COULD_NOT_BE_INSTALLED="could not be installed"
declare -r ERROR_MSG_NOT_FOUND="not found"
declare -r ERROR_MSG_SUDO="use: sudo ./scripts/init.sh or sudo make init"

######################################################################
#                                                                    #
# 2. SCRIPT PERMISSIONS                                              #
#                                                                    #
######################################################################

if [[ $EUID -ne 0 ]]; then
  echo "${ERROR_MSG_SUDO}"
  exit 1
fi

######################################################################
#                                                                    #
# 3. CHECK REQUIRED SCRIPT DEPENDENCIES                              #
#                                                                    #
######################################################################

for REQUIRED_SCRIPT_DEPENDENCY in "${REQUIRED_SCRIPT_DEPENDENCIES[@]}"
do
  if ! command -v "${REQUIRED_SCRIPT_DEPENDENCY}"; then
    echo "${REQUIRED_SCRIPT_DEPENDENCY}: ${ERROR_MSG_NOT_FOUND}"
    exit 1
  fi
done

######################################################################
#                                                                    #
# 4. FUNCS TO INSTALL NON APT PKGS                                   #
#                                                                    #
######################################################################

function install_bashunit() {
  if [ ! -f "${NON_APT_PKG_BASHUNIT_PATH}" ]; then
    curl -s "${NON_APT_PKG_BASHUNIT_REPO_URL}" | bash
  fi

  if [ ! -f "${NON_APT_PKG_BASHUNIT_PATH}" ]; then
    return 1
  fi

  return 0
}

function install_editorconfig() {
  if ! command -v "${NON_APT_PKG_EDITORCONFIG_NAME}" > /dev/null 2>&1; then
    npm i -f -g "${NON_APT_PKG_EDITORCONFIG_REPO_URL}"
  fi

  if command -v "${NON_APT_PKG_EDITORCONFIG_NAME}" > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

######################################################################
#                                                                    #
# 5. INSTALL APT DEPENDENCIES                                        #
#                                                                    #
######################################################################

for APT_PKG_TO_INSTALL in "${APT_PKGS_TO_INSTALL[@]}"
do
  if ! command -v "${APT_PKG_TO_INSTALL}" > /dev/null 2>&1; then
    apt install "${APT_PKG_TO_INSTALL}" -y
  fi
done

######################################################################
#                                                                    #
# 6. INSTALL NON APT DEPENDENCIES                                    #
#                                                                    #
######################################################################

if ! install_bashunit; then
  echo "${NON_APT_PKG_BASHUNIT_NAME}: ${ERROR_MSG_COULD_NOT_BE_INSTALLED}"
  exit 1
fi

if ! install_editorconfig; then
  echo "${NON_APT_PKG_EDITORCONFIG_NAME}: ${ERROR_MSG_COULD_NOT_BE_INSTALLED}"
  exit 1
fi
