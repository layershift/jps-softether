#!/bin/bash

. config.sh

if [ ! -f /root/.vpn_svr.shadow ]; then
    echo "Error: admin password shadow is missing";
    exit 1;
else
    server_passwd=$(cat /root/.vpn_svr.shadow);
fi


#./getEnvIP.sh 2>/dev/null | grep -v "null" > envsIPList.txt

hostPublicIP=$(hostname -i)

privateSubnets=$(./getEnvPrivateIP.sh 2>/dev/null | awk -F "." '{print $1"."$2"."$3}' | sort | uniq | awk '{print $0".0/255.255.255.0/192.168.101.1"}' | tr '\n' ',' | sed 's#,$##g')

publicIP=$(./getEnvPublicIP.sh 2>/dev/null | grep -v "$hostPublicIP" | awk '{print $0"/255.255.255.255/192.168.101.1"}' | tr '\n' ',' | sed 's#,$##g')


echo $publicIP,$privateSubnets |tr "," ",\n">&2;


/usr/local/vpnserver/vpncmd 127.0.0.1:5555 /SERVER /PASSWORD:$server_passwd /ADMINHUB:myvpn /CMD DhcpSet /start=192.168.101.2 /end=192.168.101.3 /mask=255.255.255.0 /expire=7200 /gw= /dns= /dns2= /domain= /log=np /PUSHROUTE=$publicIP,$privateSubnets
