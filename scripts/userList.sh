#!/bin/bash

if [ ! -f /root/.vpn_svr.shadow ]; then
    echo "Error: admin password shadow is missing";
    exit 1;
else
    server_passwd=$(cat /root/.vpn_svr.shadow);
fi

/usr/local/vpnserver/vpncmd 127.0.0.1:5555 /SERVER /PASSWORD:$server_passwd /ADMINHUB:myvpn /CMD UserList
