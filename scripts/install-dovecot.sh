#!/usr/bin/env bash

set -euo pipefail

root_dir="$(dirname "${BASH_SOURCE[0]}")/.."
declare -r root_dir

#
# Common properties
#
declare -r dovecot="dovecot"
declare -r dovecot_status_active="Active: active"
declare -r dovecot_status_inactive="Active: inactive"

#
# Required dependencies
#
declare required_dependency
declare -a required_dependencies=( "apt" "service" )

#
# Packages to install
#
declare package_to_install
declare -a packages_to_install=( "libsasl2-modules" "sasl2-bin" "${dovecot}-core" "${dovecot}-imapd" "${dovecot}-pop3d" "${dovecot}-mysql" )

#
# Permissions
#
if [[ $EUID -ne 0 ]]; then
  echo "use: sudo ./scripts/install-dovecot.sh, sudo make install-dovecot"
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
# Dovecot check
#
if [ "$(service "${dovecot}" status | grep -c "${dovecot_status_active}")" -gt 0 ]; then
  echo "${dovecot}: installed and active"
  exit 1
fi

if [ "$(service "${dovecot}" status | grep -c "${dovecot_status_inactive}")" -gt 0 ]; then
  echo "${dovecot}: installed and inactive"
  exit 1
fi

#
# Install packages
#
for package_to_install in "${packages_to_install[@]}"
do
  apt install "${package_to_install}" -y
done

#
# Copy SQL def
#
declare -r conf_dir_source="${root_dir}/conf"
declare -r dovecot_dir_dest="/etc/dovecot"
declare -r dovecot_conf_dir_dest="${dovecot_dir_dest}/conf.d"

declare -r dove_conf_base_file="dovecot.conf"
declare -r dove_conf_mail_file="dovecot-10-mail.conf"
declare -r dove_conf_sql_file="dovecot-sql.conf"

declare -r dove_conf_base_source_path="${conf_dir_source}/${dove_conf_base_file}"
declare -r dove_conf_base_dest_path="${dovecot_dir_dest}/${dove_conf_base_file}"

declare -r dove_conf_mail_source_path="${conf_dir_source}/${dove_conf_mail_file}"
declare -r dove_conf_mail_dest_path="${dovecot_conf_dir_dest}/10-mail.conf"

declare -r dove_conf_sql_source_path="${conf_dir_source}/${dove_conf_sql_file}"
declare -r dove_conf_sql_dest_path="${dovecot_dir_dest}/${dove_conf_sql_file}"

declare -A conf_files_to_cpy
conf_files_to_cpy["${dove_conf_base_source_path}"]="${dove_conf_base_dest_path}"
conf_files_to_cpy["${dove_conf_mail_source_path}"]="${dove_conf_mail_dest_path}"
conf_files_to_cpy["${dove_conf_sql_source_path}"]="${dove_conf_sql_dest_path}"

declare i
declare key=""
declare path=""
declare path_dest=""
declare path_dest_bak=""
declare path_source=""
declare -a paths=()

for key in "${!conf_files_to_cpy[@]}"; do
	
	if [ -z "${key}" ]; then
		echo "key: empty"
		exit 1
	fi

	path_source="${key}"
	path_dest="${conf_files_to_cpy[${key}]}"
	path_dest_bak="${path_dest}.bak"

	paths+=("${path_source}")
	paths+=("${path_dest}")
	paths+=("${path_dest_bak}")

  for i in "${!paths[@]}"; do
		path="${paths[${i}]}"

	  if [ -z "${path}" ]; then
			echo "path (${i}): empty"
		  exit 1
	  fi
	done
	
	if [ ! -f "${path_source}" ]; then
		echo "${path_source}: not found"
		exit 1
	fi

	if [ -f "${path_dest_bak}" ]; then
		rm -f "${path_dest_bak}"
	fi

	if [ -f "${path_dest}" ]; then
		mv "${path_dest}" "${path_dest}.bak"
	fi

	cp -f "${path_source}" "${path_dest}"
	chown root:root "${path_dest}"
	chmod 0600 "${path_dest}"
	
	path_source=""
	path_dest=""
	path_dest_bak=""
	paths=()
done

usermod -a -G mail dovenull
usermod -a -G mail dovecot

#
# If the 'dovecot_imap_service' user has not been created,
# then undertake the creation process directly below,
# ensuring that the user has a UID of 2000 and a GID of 8.
#
if [ "$(cat /etc/passwd | grep -c "dovecot_imap_service")" -eq 0 ]; then 
  useradd                                                \
    -r                                                   \
		-u 2000                                              \
	  -c "This is the Dovecot IMAP server user"            \
	  -g "$(cat /etc/group | grep mail | cut -f 3 -d ":")" \
    dovecot_imap_service
fi

chmod -R 1777 /var/mail/

#
# Config
#
cat << EOF > /etc/dovecot/conf.d/10-auth.conf
auth_mechanisms = plain login
disable_plaintext_auth = no
EOF

cat << EOF > /etc/dovecot/conf.d/10-logging.conf
auth_debug = yes
auth_debug_passwords = yes
auth_verbose_passwords=plain
auth_verbose = yes

log_debug = category=mail
log_path = /var/log/dovecot.log

mail_debug=yes 
EOF


cat << EOF > /etc/dovecot/conf.d/10-master.conf
service imap-login {
  inet_listener imap {
    #port = 143
  }
  inet_listener imaps {
    #port = 993
    #ssl = yes
  }
}

service pop3-login {
  inet_listener pop3 {
    #port = 110
  }
  inet_listener pop3s {
    #port = 995
    #ssl = yes
  }
}

service submission-login {
  inet_listener submission {
    #port = 587
  }
  inet_listener submissions {
    #port = 465
  }
}

service lmtp {
  unix_listener lmtp {
    #mode = 0666
  }
}

service imap {
  #process_limit = 1024
}

service pop3 {
  #process_limit = 1024
}

service submission {
  #process_limit = 1024
}

service auth {
  unix_listener auth-userdb {
    mode = 0777
    user = root
    group = root
  }
  unix_listener auth-client {
    mode = 0777
    user = Debian-exim
    group = mail
  }
}

service dict {
  unix_listener dict {
    #mode = 0600
    #user =
    #group =
  }
}

userdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf
}

passdb {
  driver = sql
	args = /etc/dovecot/dovecot-sql.conf
}
EOF
