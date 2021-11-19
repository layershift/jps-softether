#!/bin/bash

. config.sh

for env_ in $(./getEnvs.sh 2>/dev/null); do

    if [ $debug -gt 0 ]; then echo $env_ >&2; fi;
    if [ $debug -gt 0 ]; then echo "curl -s \"https://app.j.layershift.co.uk/1.0/environment/control/rest/getenvinfo?session=$token&envName=$env_\" | jq  '.nodes[] | .extIPs[]?' | sed \"s#\\\"##g\" " >&2; fi
    curl -s "https://app.j.layershift.co.uk/1.0/environment/control/rest/getenvinfo?session=$token&envName=$env_" | jq  '.nodes[] | .extIPs[]?' | sed "s#\"##g"

done;
