#!/usr/bin/env bash

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive


######################################################################
######################################################################
#                                                                    #
# 1. Define common vars                                              #
#                                                                    #
######################################################################
######################################################################


######################################################################
#                                                                    #
# 1.1 Define core vars                                               #
#                                                                    #
######################################################################

#
# Root
#
declare script_dir
script_dir="$(dirname "${BASH_SOURCE[0]}")"

#
# App
#
declare -r app="dovecot"

#
# Common dirs
#
declare -r conf_dir="/etc/${app}/conf.d"
declare -r home_dir="/home"


#
# Common paths
#
declare -r bash_path="/usr/bin/bash"
declare -r users_list_path="/etc/passwd"

#
# Exim
#
declare -r exim_grp="mail"
declare -r exim_user="Debian-exim"

#
# Exim rcpts
#
declare       rcpt_user
declare    -r rcpt_grp="${exim_grp}"
declare    -r rcpt_pass="Titania09"
declare       rcpt_required_file_path
declare -a -r rcpt_required_file_paths=( "${bash_path}" "${users_list_path}" )
declare -a -r rcpt_users=( "admin" "joealdersonstrachan" )


######################################################################
#                                                                    #
# 1.2 Define required script dependencies                            #
#                                                                    #
######################################################################

declare    required_script_dependency
declare -a required_script_dependencies=(
  "apt"
  "chmod"
	"chpasswd"
  "chown"
  "grep"
  "groupadd"
  "useradd"
)

######################################################################
#                                                                    #
# 1.3 Define packages to install                                     #
#                                                                    #
######################################################################

declare    package_to_install
declare -a packages_to_install=(
  "${app}-core"
  "${app}-imapd"
  "${app}-pop3d"
  "libsasl2-modules"
  "sasl2-bin"
)

######################################################################
#                                                                    #
# 1.4 Define config file names                                       #
#                                                                    #
######################################################################

declare -r auth_conf="10-auth.conf"
declare -r logging_conf="10-logging.conf"
declare -r master_conf="10-master.conf"


######################################################################
#                                                                    #
# 1.5 Define files to cp (post install)                              #
#                                                                    #
######################################################################

declare -A files_to_cp_post_install

# [ source_file_path ] = destination_file_path

files_to_cp_post_install["${script_dir}/${auth_conf}"]="${conf_dir}/${auth_conf}"
files_to_cp_post_install["${script_dir}/${logging_conf}"]="${conf_dir}/${logging_conf}"
files_to_cp_post_install["${script_dir}/${master_conf}"]="${conf_dir}/${master_conf}"
files_to_cp_post_install["${users_list_path}"]="${conf_dir}/${master_conf}"

declare -r backup_suffix="bak"
declare    destination_file_path
declare    source_file_path


######################################################################
######################################################################
#                                                                    #
# 2 Common funcs                                                     #
#                                                                    #
######################################################################
######################################################################


######################################################################
#                                                                    #
# 2.1 Is known user                                                  #
#                                                                    #
######################################################################

function is_known_user() {
  local -r user=$1

  if [[ "$(grep -c "${user}" "${users_list_path}")" -eq 0 ]]; then
    return 1
  fi

  return 0
}


######################################################################
#                                                                    #
# 2.2 Create user                                                    #
#                                                                    #
######################################################################

function create_user() {
  #
  # Input vars
  #
  local -r user=$1

  #
  # Does the user already exist?
  #
  if is_known_user "${user}"; then
    return 1
  fi

  #
  # Create the user
  #
  useradd                  \
    -d "/var/spool/exim"   \
    -g "mail"              \
    -s "/usr/sbin/nologin" \
    "${user}" > /dev/null
}


######################################################################
######################################################################
#                                                                    #
# 3 PRE INSTALL                                                      #
#                                                                    #
######################################################################
######################################################################


######################################################################
#                                                                    #
# 3.1 Check script permissions                                       #
#                                                                    #
######################################################################

if [[ $EUID -ne 0 ]]; then
  echo "use: sudo ./install.sh" >> /dev/stderr
  exit 1
fi


######################################################################
#                                                                    #
# 3.2 Check required script dependencies                             #
#                                                                    #
######################################################################

for required_script_dependency in "${required_script_dependencies[@]}"
do
  if ! command -v "${required_script_dependency}" > /dev/null 2>&1; then
    echo "${required_script_dependency}: not found" >> /dev/stderr
    exit 1
  fi
done


######################################################################
######################################################################
#                                                                    #
#  4 INSTALL                                                         #
#                                                                    #
######################################################################
######################################################################

for package_to_install in "${packages_to_install[@]}"
do
    apt install "${package_to_install}" -y
done


######################################################################
######################################################################
#                                                                    #
# 5 POST INSTALL                                                     #
#                                                                    #
######################################################################
######################################################################


######################################################################
#                                                                    #
# 5.1 CP files                                                       #
#                                                                    #
######################################################################

for source_file_path in "${!files_to_cp_post_install[@]}"
do
  destination_file_path="${files_to_cp_post_install[${source_file_path}]}"

  if [ ! -f "${source_file_path}" ]; then
    echo "${source_file_path}: not found" >> /dev/stderr
    exit 1
  fi

  if [ -f "${destination_file_path}" ]; then
    mv -f "${destination_file_path}" "${destination_file_path}.${backup_suffix}"
  fi

  cp "${source_file_path}" "${destination_file_path}"
done


######################################################################
######################################################################
#                                                                    #
# 6 POST INSTALLATION USER CREATION                                  #
#                                                                    #
######################################################################
######################################################################


######################################################################
#                                                                    #
# 6.1 Check rcpt_required_file_paths                                 #
#                                                                    #
######################################################################

for rcpt_required_file_path in "${rcpt_required_file_paths[@]}"
do
  if [ ! -f "${rcpt_required_file_path}" ]; then
    echo "${rcpt_required_file_path}: not found" >> /dev/stderr
    exit 1
  fi
done


######################################################################
#                                                                    #
# 6.2 Create rcpt_grp (if not present)                               #
#                                                                    #
######################################################################

if [ "$(getent group | grep -c "${rcpt_grp}")" -eq 0 ]; then
  groupadd "${rcpt_grp}"
fi


######################################################################
#                                                                    #
# 6.3 Create rcpt_users (if not present)                             #
#                                                                    #
######################################################################

for rcpt_user in "${rcpt_users[@]}"
do
  if ! is_known_user "${rcpt_user}"; then

    useradd -m                      \
      -d "${home_dir}/${rcpt_user}" \
      -s "${bash_path}"             \
      "${rcpt_user}"

    usermod -a -G "${rcpt_grp}" "${rcpt_user}"

    echo "${rcpt_user}:${rcpt_pass}" | chpasswd
  fi
done


######################################################################
#                                                                    #
# 6.4 Create exim_grp (if not present)                               #
#                                                                    #
######################################################################

if [ "$(getent group | grep -c "${exim_grp}")" -eq 0 ]; then
  groupadd "${exim_grp}"
fi


######################################################################
#                                                                    #
# 6.5 Create exim_user (if not present)                              #
#                                                                    #
######################################################################

if ! is_known_user "${exim_user}"; then
   create_user "${exim_user}"
fi
