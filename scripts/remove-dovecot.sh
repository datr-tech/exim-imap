#!/usr/bin/env bash

set -euo pipefail

#
# Common vars
#
declare -r dovecot="dovecot"
declare -r dovecot_status_active="Active: active"

#
# Required dependencies
#
declare required_dependency
declare -a required_dependencies=( "apt" "${dovecot}" )

#
# Packages to remove
#
declare package_to_remove
declare -a packages_to_remove=( "${dovecot}-core" "libsasl2-modules" "sasl2-bin" "dovecot-imapd" "dovecot-pop3d" )

#
# Packages to purge
#
declare package_to_purge
declare -a packages_to_purge=( "${dovecot}*" )

#
# Permissions
#
if [[ $EUID -ne 0 ]]; then
  echo "use: sudo ./scripts/remove-${dovecot}.sh, sudo make remove-${dovecot}"
  exit 1
fi

#
# Dependencies
#
for required_dependency in "${required_dependencies[@]}"
do
  if ! command -v "${required_dependency}" > /dev/null 2>&1; then
    echo "${required_dependency}: not found"
    exit 1
  fi
done

#
# Check dovecot
#
if [ "$(service "${dovecot}" status | grep -c "${dovecot_status_active}")" -gt 0 ]; then
  echo "${dovecot}: active"
  exit 1
fi

#
# Remove packages
#
for package_to_remove in "${packages_to_remove[@]}"
do
  apt remove "${package_to_remove}" -y
done

#
# Purge packages
#
for package_to_purge in "${packages_to_purge[@]}"
do
  apt purge "${package_to_purge}" -y
done

#
# Remove the dovecot_imap_service user
#
if [ "$(cat /etc/passwd | grep -c "dovecot_imap_service")" -gt 0 ]; then 
  userdel -r dovecot_imap_service
fi
