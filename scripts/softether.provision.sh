#!/bin/bash
#conf vps server default

freshInstall=1;

if [ ! -f /root/.vpn_svr.shadow ]; then
    openssl rand -base64 12 > /root/.vpn_svr.shadow;
    server_passwd=$(cat /root/.vpn_svr.shadow);
else
    freshInstall=0;
    fileLines=$(cat /root/.vpn_svr.shadow | wc -l);
    if [ $fileLines -eq 1 ]; then
	server_passwd=$(cat /root/.vpn_svr.shadow);
	echo "Info: Use passwor $server_passwd"
    else
	echo "Error: Server password shadow exists but invalid!"
    fi
fi

if [ ! -f  /root/.vpn_hub.shadow ]; then
    openssl rand -base64 12 >  /root/.vpn_hub.shadow;
    hub_passwd=$(cat  /root/.vpn_hub.shadow);
else
    freshInstall=0;
    fileLines=$(cat /root/.vpn_hub.shadow | wc -l);
    if [ $fileLines -eq 1 ]; then
	hub_passwd=$(cat  /root/.vpn_hub.shadow);
    else
	echo "Error: Hub password shadow exists but invalid!"
    fi
fi

cat << EOF > /usr/local/vpnserver/default.conf
HubDelete DEFAULT
ListenerDelete 443
ListenerDelete 992
ListenerDelete 1194

ServerPasswordSet $server_passwd

BridgeCreate myvpn /DEVICE:vpn /TAP:yes

SyslogDisable
VpnAzureSetEnable no
SstpEnable no
VpnOverIcmpDnsEnable /icmp=no /dns=no
KeepDisable
OpenVpnEnable no /PORTS:1194

HubCreate myvpn /password=$hub_passwd
hub myvpn
SetEnumDeny
SyslogDisable
SetMaxSession 10

LogPacketSaveType /type=tcpconn /save=none
LogPacketSaveType /type=tcpdata /save=none
LogPacketSaveType /type=dhcp /save=none
LogPacketSaveType /type=udp /save=none
LogPacketSaveType /type=icmp /save=none
LogPacketSaveType /type=ip /save=none
LogPacketSaveType /type=arp /save=none
LogPacketSaveType /type=ether /save=none

LogSwitchSet security /switch=day
LogSwitchSet packet /switch=day

LogDisable packet

Flush
Reboot
EOF

#NatEnable
#SecureNatEnable
#SecureNatHostSet /ip=192.168.101.1 /mask=255.255.255.0 /mac=
#DhcpEnable
#DhcpSet /start=192.168.101.2 /end=192.168.101.100 /mask=255.255.255.0 /expire=7200 /gw= /dns= /dns2= /domain= /log=np /PUSHROUTE=1.1.1.1/255.255.255.255/192.168.101.1

if [ $freshInstall -eq 0 ]; then
    /usr/local/vpnserver/vpncmd 127.0.0.1:5555 /SERVER /PASSWORD:$server_passwd /in:/usr/local/vpnserver/default.conf
else
    /usr/local/vpnserver/vpncmd 127.0.0.1:5555 /SERVER /in:/usr/local/vpnserver/default.conf
fi

#cleanup
rm -f /usr/local/vpnserver/default.conf

systemctl stop vpnserver
line=$(grep -A 19 -n DDnsClient /usr/local/vpnserver/vpn_server.config | grep -m1 -B19 "}" | grep "bool Disabled" | awk -F "-" '{print $1}')
sed $line's/false/true/' -i /usr/local/vpnserver/vpn_server.config
line=$(grep -n DisableJsonRpcWebApi /usr/local/vpnserver/vpn_server.config |awk -F ":" '{print $1}')
sed $line's/false/true/' -i /usr/local/vpnserver/vpn_server.config

#sed 's#\#/usr/sbin/ip#/usr/sbin/ip#g' -i /usr/local/vpnserver/vpnserver.sh

systemctl start vpnserver

