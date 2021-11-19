#!/bin/bash

. config.sh

envName=$(hostname -s | sed 's#node.*[0-9]-##')

if [ $debug -gt 0 ]; then echo "curl -s \"https://app.j.layershift.co.uk/1.0/environment/control/rest/getenvinfo?session=$token&envName=$envName\" 2>/dev/null | jq '.env.hostGroup.displayName' | sed \"s#\\\"##g\"">&2; fi
envRegion=$(curl -s "https://app.j.layershift.co.uk/1.0/environment/control/rest/getenvinfo?session=$token&envName=$envName" 2>/dev/null| jq '.env.hostGroup.displayName' | sed "s#\"##g")


#if [ $debug -gt 0 ]; then echo "curl -s \"https://app.j.layershift.co.uk/1.0/environment/control/rest/getenvs?session=$token&lazy=true\" | jq  \".infos[].env.envName\" | sed \"s#\\\"##g\"" >&2; fi
#curl -s "https://app.j.layershift.co.uk/1.0/environment/control/rest/getenvs?session=$token&lazy=true&appid=" | jq  ".infos[].env.envName" | sed "s#\"##g"


if [ $debug -gt 0 ]; then echo "curl -s \"https://app.j.layershift.co.uk/1.0/environment/control/rest/getenvs?session=$token&lazy=true\" | jq '.infos[] | select(.env.hostGroup.displayName==\"$envRegion\") | .env.envName' | sed \"s#\\\"##g\"" >&2; fi
curl -s "https://app.j.layershift.co.uk/1.0/environment/control/rest/getenvs?session=$token&lazy=true" | jq '.infos[] | select(.env.hostGroup.displayName=="'$envRegion'") | .env.envName' | sed "s#\"##g"
