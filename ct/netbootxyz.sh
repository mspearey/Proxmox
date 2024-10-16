#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/mspearey/Proxmox/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Authors: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    _   __     __  __                __                  
   / | / /__  / /_/ /_  ____  ____  / /_  _  ____  ______
  /  |/ / _ \/ __/ __ \/ __ \/ __ \/ __/ | |/_/ / / /_  /
 / /|  /  __/ /_/ /_/ / /_/ / /_/ / /__ _>  </ /_/ / / /_
/_/ |_/\___/\__/_.___/\____/\____/\__(_)_/|_|\__, / /___/
                                            /____/       
EOF
}
header_info
echo -e "Loading..."
APP="Netbootxyz"
var_disk="20"
var_cpu="1"
var_ram="1024"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="0"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr3"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="yes"
  VERB="yes"
  echo_default
}

function update_script() {
  if [[ ! -f /etc/supervisor.conf ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
  msg_error "There is currently no update path available."
  exit  
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:5000${CL} \n"