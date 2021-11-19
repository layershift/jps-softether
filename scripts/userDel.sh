#!/bin/bash

if [ ! -f /root/.vpn_svr.shadow ]; then
    echo "Error: admin password shadow is missing";
    exit 1;
else
    server_passwd=$(cat /root/.vpn_svr.shadow);
fi

if [ -z $1 ]; then
    echo -n "Username to delete:";
    read userName;
else
    userName=$1;
fi

if [ -z $userName ]; then
    echo "Error: username not specified"
    exit 1;
fi

#/usr/local/vpnserver/vpncmd 127.0.0.1:5555 /SERVER /PASSWORD:$server_passwd /ADMINHUB:myvpn /CMD UserList
userList=$(/usr/local/vpnserver/vpncmd 127.0.0.1:5555 /SERVER /PASSWORD:$server_passwd /ADMINHUB:myvpn /CMD UserList | grep "User Name" | awk -F "|" '{print $2}')

echo $userList |grep -q $userName 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Error: user doesn't exist";
    exit;
fi

/usr/local/vpnserver/vpncmd 127.0.0.1:5555 /SERVER /PASSWORD:$server_passwd /ADMINHUB:myvpn /CMD UserDelete $userName 2>&1 1>/dev/null
if [ $? -ne 0 ]; then
    echo "Error: failed to delete";
else
    echo "Info: user deleted";
fi

/usr/local/vpnserver/vpncmd 127.0.0.1:5555 /SERVER /PASSWORD:$server_passwd /CMD Flush 2>&1 1>/dev/null
