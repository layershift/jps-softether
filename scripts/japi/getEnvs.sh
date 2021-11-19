#!/bin/bash

. config.sh

if [ $debug -gt 0 ]; then echo "curl -s \"https://app.j.layershift.co.uk/1.0/environment/control/rest/getenvs?session=$token&lazy=true\" | jq  \".infos[].env.envName\" | sed \"s#\\\"##g\"" >&2; fi
curl -s "https://app.j.layershift.co.uk/1.0/environment/control/rest/getenvs?session=$token&lazy=true&appid=" | jq  ".infos[].env.envName" | sed "s#\"##g"
