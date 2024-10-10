#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Authors: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y --no-install-recommends \
  bash \
  busybox \
  curl \
  git \
  jq \
  nginx \
  sudo \
  supervisor \
  syslog-ng \
  tar \
  dnsmasq

#$STD apt-get install -y --no-cache --virtual=build-dependencies \
#   npm

msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Installed Node.js"

WEBAPP_VERSION=$(curl -sX GET "https://api.github.com/repos/netbootxyz/webapp/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]');
msg_info "Installing Netbootxyz $WEBAPP_VERSION"

groupmod -g 1000 users
useradd -u 1011 -U -d /config -s /bin/false nbxyz
usermod -G users nbxyz
mkdir /app \
      /config \
      /defaults

wget -q https://github.com/netbootxyz/webapp/archive/${WEBAPP_VERSION}.tar.gz -O /opt/webapp.tar.gz
        
tar xf /opt/webapp.tar.gz -C /app/ --strip-components 1
$STD npm install --prefix /app
apk del --purge build-dependencies

cp root/defaults /defaults
cp root/etc /etc

$STD /opt/root/init.sh

msg_ok "Installed Netbootxyz $WEBAPP_VERSION"

supervisord -c /etc/supervisor.conf
msg_ok "Configured Services"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get autoremove
$STD apt-get autoclean
msg_ok "Cleaned"