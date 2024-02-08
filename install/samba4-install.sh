#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

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
 libnss-winbind \
 krb5-config \
 krb5-user \
 dnsutils \
 python3-setproctitle
msg_ok "Installed Dependencies"

msg_info "Installing Samba"
$STD apt-get install -y samba
msg_ok "Installed Samba"

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
