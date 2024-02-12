#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

kerb() {
  ADMINTOKEN=''
  if NEWTOKEN=$(whiptail --passwordbox "Setup your ADMIN_TOKEN (make it strong)" 10 58 3>&1 1>&2 2>&3); then
    if [[ ! -z "$NEWTOKEN" ]]; then
      ADMINTOKEN=$(echo -n ${NEWTOKEN} | argon2 "$(openssl rand -base64 32)" -e -id -k 19456 -t 2 -p 1)
    else
      clear
      echo -e "⚠  User didn't setup ADMIN_TOKEN, admin panel is disabled! \n"
    fi
  else
    clear
    echo -e "⚠  User didn't setup ADMIN_TOKEN, admin panel is disabled! \n"
  fi
}

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Disabling Resolv Conf"
echo 'make_resolv_conf() { :; }' > /etc/dhcp/dhclient-enter-hooks.d/leave_my_resolv_conf_alone
chmod 755 /etc/dhcp/dhclient-enter-hooks.d/leave_my_resolv_conf_alone
msg_info "Disabled Resolv Conf"

msg_info "Installing Dependencies"
$STD apt-get install -y acl \
 attr \
 winbind \
 libpam-winbind \
 libnss-winbind

# domain details
kerb()

# krb4-config shows interactive dialog. Can configure later.
$STD DEBIAN_FRONTEND=noninteractive apt-get install -y krb5-config

$STD apt-get install -y krb5-user \
 dnsutils \
 python3-setproctitle
msg_ok "Installed Dependencies"

msg_info "Installing Samba"
$STD apt-get install -y samba
msg_ok "Installed Samba"

sed '/\[realms\]/ a\
        COOP.SPEAREY.COM = { \
                kdc = SambaDC.COOP.SPEAREY.COM \
                admin_server = SambaDC.COOP.SPEAREY.COM \
        }' /etc/krb5.conf
###
        workgroup = EXAMPLE 
        realm = EXAMPLE.COM 
        netbios name = SAMBA4 
        server role= active directory domain controller 
        dns forwarder = 8.8.8.8

##
[netlogon] 
comment = Network Logon Service 
path =/var/lib/samba/sysvol/example.com/scripts 
read only = No 
[sysvol] 
comment = System Volume 
path = /var/lib/samba/sysvol 
read only = No

mv /etc/samba/smb.conf /etc/samba/smb.conf.initial
$STD samba-tool domain provision --use-rfc2307 --interactive

# configure dns resolver
#search samdom.example.com
#nameserver 10.99.0.1

# configure kerberos

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/samba.service
[Unit]
Description=Samba
[Service]
Type=simple
WorkingDirectory=/root/.samba
ExecStart=/srv/samba/bin/hass -c "/root/.samba"
Restart=always
RestartForceExitStatus=100
EOF
$STD systemctl enable --now samba
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get autoremove
$STD apt-get autoclean
msg_ok "Cleaned"
