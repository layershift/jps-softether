#!/bin/bash

cd "$(dirname "$0")"

#set -x 
. config.sh

if [ ! -f /root/.vpn_svr.shadow ]; then
    echo "Error: admin password shadow is missing";
    exit 1;
else
    server_passwd=$(cat /root/.vpn_svr.shadow);
fi

# write filter rules to file
# params
# $1 - file full path
filterRules(){
    insertLine=$(grep -n -m1 "###SoftetherCustomFilterRulesBegin" $1 | awk -F ":" '{print $1}')
    insertLine=$((insertLine+1))
    sed -i $insertLine'i-I INPUT -p tcp -m tcp --dport 5555 -j ACCEPT' $1
    sed -i $insertLine'i-I INPUT -i tap_vpn -j ACCEPT' $1
    sed -i $insertLine'i-I OUTPUT -o tap_vpn -j ACCEPT' $1
    sed -i $insertLine'i-I FORWARD -o tap_vpn -j ACCEPT' $1
    sed -i $insertLine'i-I FORWARD -i tap_vpn -j ACCEPT' $1
}

# write nat rules to file
# params:
# $1 - file full path
# $2 - , separated rules variable
natRules(){
    insertLine=$(grep -n -m1 "###SoftetherCustomNatRulesBegin" $1 | awk -F ":" '{print $1}')
    insertLine=$((insertLine+1))

    while IFS= read -r rule; do
	sed -i $insertLine"i$rule" $1
    done <<< "$(echo $2 | tr "," "\n")"
}

#./getEnvIP.sh 2>/dev/null | grep -v "null" > envsIPList.txt

hostPublicIP=$(hostname -i)
hostPublicIP=$(hostname -I | tr " " "\n" | egrep -v "127.0.0.1|192.168.101.1|^$" | grep -v "^10\.")
hostPrivateIp=$(hostname -I | tr " " "\n" | egrep -v "127.0.0.1|192.168.101.1|^$" | grep "^10\.")

read -r dns1 dns2 <<<$(cat /etc/resolv.conf  | grep nameserver | head -n2 | awk '{print $NF}')

privateSubnets_=$(./getEnvPrivateIP.sh 2>/dev/null | awk -F "." '{print $1"."$2"."$3}' | sort | uniq | awk '{print $0".0/24"}')
#echo $privateSubnets

#privateSubnets=$(./getEnvPrivateIP.sh 2>/dev/null | awk -F "." '{print $1"."$2"."$3}' | sort | uniq | awk '{print $0".0/24/192.168.101.1"}' | tr '\n' ',' | sed 's#,$##g')
privateSubnets=$(echo $privateSubnets_ | tr " " "\n" | awk '{print $0",192.168.101.1"}' | tr '\n' ',' | sed 's#,$##g')

privateSubnetsFirewallRules=""

for subnet in $(echo $privateSubnets_); do
    privateSubnetsFirewallRules="$privateSubnetsFirewallRules-I POSTROUTING -d $subnet -j SNAT --to-source $hostPrivateIp,";
done;
privateSubnetsFirewallRules=$(echo $privateSubnetsFirewallRules | sed 's#,$##g')

#echo $privateSubnets

publicIP_=$(./getEnvPublicIP.sh 2>/dev/null | grep -v "$hostPublicIP" | awk -F "." '{print $1"."$2"."$3}' | sort | uniq | awk '{print $0".0/24"}')

#/192.168.101.1"}' | tr '\n' ',' | sed 's#,$##g')

#publicIP=$(./getEnvPublicIP.sh 2>/dev/null | grep -v "$hostPublicIP" | awk -F "." '{print $1"."$2"."$3}' | sort | uniq | awk '{print $0".0/24/192.168.101.1"}' | tr '\n' ',' | sed 's#,$##g')
publicIP=$(echo $publicIP_ | tr " " "\n" | awk '{print $0",192.168.101.1"}' | tr '\n' ',' | sed 's#,$##g')

publicIPFirewallRules=""

for subnet in $(echo $publicIP_); do
    publicIPFirewallRules="$publicIPFirewallRules-I POSTROUTING -d $subnet -j SNAT --to-source $hostPublicIP,";
done;
publicIPFirewallRules=$(echo $publicIPFirewallRules | sed 's#,$##g')


#echo $publicIP,$privateSubnets |tr "," ",\n">&2;

sed 's#dhcp-option=121,.*#dhcp-option=121,'$publicIP,$privateSubnets'#g' -i /etc/dnsmasq.d/vpnserver.conf
sed 's#dhcp-option=249,.*#dhcp-option=249,'$publicIP,$privateSubnets'#g' -i /etc/dnsmasq.d/vpnserver.conf

systemctl restart dnsmasq

grep -q "*filter" /etc/sysconfig/iptables-custom 2>/dev/null
if [ $? -ne 0 ]; then
    echo "*filter" >> /etc/sysconfig/iptables-custom
    echo "###SoftetherCustomFilterRulesBegin" >> /etc/sysconfig/iptables-custom
    echo "###SoftetherCustomFilterRulesEnd" >> /etc/sysconfig/iptables-custom
    echo "COMMIT" >> /etc/sysconfig/iptables-custom
    filterRules /etc/sysconfig/iptables-custom
else
    grep -q "###SoftetherCustomFilterRulesBegin" /etc/sysconfig/iptables-custom
    if [ $? -ne 0 ]; then
#	grep -n "*filter" /etc/sysconfig/iptables-custom -A 200 | grep COMMIT -n1
	filterCommitLine=$(grep -n "*filter" /etc/sysconfig/iptables-custom -A 200 | grep COMMIT -m1 | awk -F "-" '{print $1}')
	sed -i $filterCommitLine'i###SoftetherCustomFilterRulesEnd' /etc/sysconfig/iptables-custom
	sed -i $filterCommitLine'i###SoftetherCustomFilterRulesBegin' /etc/sysconfig/iptables-custom
    else
	beginLine=$(grep -n "###SoftetherCustomFilterRulesBegin" /etc/sysconfig/iptables-custom | awk -F ":" '{print $1}')
	beginLine=$((beginLine+1))
	grep -q "###SoftetherCustomFilterRulesEnd" /etc/sysconfig/iptables-custom
	if [ $? -ne 0 ]; then
#	    echo "here"
#	    echo "sed -i $beginLine'i###SoftetherCustomFilterRulesEnd' /etc/sysconfig/iptables-custom"
	    sed -i $beginLine'i###SoftetherCustomFilterRulesEnd' /etc/sysconfig/iptables-custom
	fi
	endLine=$(grep -n "###SoftetherCustomFilterRulesEnd" /etc/sysconfig/iptables-custom | awk -F ":" '{print $1}')
	endLine=$((endLine-1))
#	echo $beginLine $endLine
#	echo "sed -e \"$beginLine,$endLine\"\"d\" -i /etc/sysconfig/iptables-custom"
	if [ $endLine -gt $beginLine ]; then
	    sed -e "$beginLine,$endLine""d" -i /etc/sysconfig/iptables-custom
	fi
    fi
    filterRules /etc/sysconfig/iptables-custom
fi
grep -q "*nat" /etc/sysconfig/iptables-custom 2>/dev/null
if [ $? -ne 0 ]; then
    echo "*nat" >> /etc/sysconfig/iptables-custom
    echo "###SoftetherCustomNatRulesBegin" >> /etc/sysconfig/iptables-custom
    echo "###SoftetherCustomNatRulesEnd" >> /etc/sysconfig/iptables-custom
    echo "COMMIT" >> /etc/sysconfig/iptables-custom
    natRules /etc/sysconfig/iptables-custom "$publicIPFirewallRules,$privateSubnetsFirewallRules"
else
    grep -q "###SoftetherCustomNatRulesBegin" /etc/sysconfig/iptables-custom
    if [ $? -ne 0 ]; then
	filterCommitLine=$(grep -n "*nat" /etc/sysconfig/iptables-custom -A 200 | grep COMMIT -m1 | awk -F "-" '{print $1}')
	sed -i $filterCommitLine'i###SoftetherCustomNatRulesEnd' /etc/sysconfig/iptables-custom
	sed -i $filterCommitLine'i###SoftetherCustomNatRulesBegin' /etc/sysconfig/iptables-custom
    else
	beginLine=$(grep -n "###SoftetherCustomNatRulesBegin" /etc/sysconfig/iptables-custom | awk -F ":" '{print $1}')
	beginLine=$((beginLine+1))
	grep -q "###SoftetherCustomNatRulesEnd" /etc/sysconfig/iptables-custom
	if [ $? -ne 0 ]; then
	    sed -i $beginLine'i###SoftetherCustomNatRulesEnd' /etc/sysconfig/iptables-custom
	fi
	endLine=$(grep -n "###SoftetherCustomNatRulesEnd" /etc/sysconfig/iptables-custom | awk -F ":" '{print $1}')
	endLine=$((endLine-1))
	if [ $endLine -gt $beginLine ]; then
	    sed -e "$beginLine,$endLine""d" -i /etc/sysconfig/iptables-custom
	fi
    fi
    natRules /etc/sysconfig/iptables-custom "$publicIPFirewallRules,$privateSubnetsFirewallRules"
fi

jem firewall fwStart

sysctl -f /etc/sysctl.d/vpnserver.conf


#/usr/local/vpnserver/vpncmd 127.0.0.1:5555 /SERVER /PASSWORD:$server_passwd /ADMINHUB:myvpn /CMD DhcpSet /start=192.168.101.2 /end=192.168.101.3 /mask=255.255.255.0 /expire=7200 /gw= /dns=192.168.101.1 /dns2= /domain= /log=np /PUSHROUTE=$publicIP,$privateSubnets
