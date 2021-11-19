#!/bin/bash

/usr/local/vpnserver/vpnserver start
#sleep 10
i=5;
while [ $i -gt 0 ]; do 
    /usr/sbin/ip link show tap_vpn 2>/dev/null 1>/dev/null; 
    if [ $? -eq 0 ]; then 
        /usr/sbin/ip addr add 192.168.101.1/24 dev tap_vpn
        break; 
    else 
        echo -n .; 
        sleep 2; 
    fi; 
    ((i--));
done;
