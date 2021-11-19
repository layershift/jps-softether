#!/bin/bash

if [ ! -f /root/.vpn_svr.shadow ]; then
    echo "Error: admin password shadow is missing";
    exit 1;
else
    server_passwd=$(cat /root/.vpn_svr.shadow);
fi

if [ -z $1 ]; then
    echo -n "New username:";
    read userName;
else
    userName=$1;
fi

#/usr/local/vpnserver/vpncmd 127.0.0.1:5555 /SERVER /PASSWORD:$server_passwd /ADMINHUB:myvpn /CMD UserList
userList=$(/usr/local/vpnserver/vpncmd 127.0.0.1:5555 /SERVER /PASSWORD:$server_passwd /ADMINHUB:myvpn /CMD UserList | grep "User Name" | awk -F "|" '{print $2}')

echo $userList |grep -q $userName
if [ $? -eq 0 ]; then
    echo "Error: user exists";
    exit;
fi

echo 'Generating 12-character passwords'
#for ((n=0;n<12;n++)); do
#    newPass=$(dd if=/dev/urandom count=1 2> /dev/null | uuencode -m - | sed -ne 2p | cut -c-12)
#done
newPass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)


status="";
/usr/local/vpnserver/vpncmd 127.0.0.1:5555 /SERVER /PASSWORD:$server_passwd /ADMINHUB:myvpn /CMD UserCreate $userName /group="" /realname="" /note="" 2>&1 1>/dev/null
if [ $? -ne 0 ]; then
    echo "Error: can't create user";
else
    echo "Info: user $userName created";
fi
/usr/local/vpnserver/vpncmd 127.0.0.1:5555 /SERVER /PASSWORD:$server_passwd /ADMINHUB:myvpn /CMD UserPasswordSet $userName /password=$newPass 2>&1 1>/dev/null
if [ $? -ne 0 ]; then
    echo "Error: can't set password";
else
    echo "Info: password set to $newPass";
fi

/usr/local/vpnserver/vpncmd 127.0.0.1:5555 /SERVER /PASSWORD:$server_passwd /CMD Flush 2>&1 1>/dev/null
