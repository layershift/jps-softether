#!/bin/bash

debug=1

if [ -f token ];then
    token=$(cat token);
else
    echo "Error: can't find token"
    exit 1;
fi

which jq 2>&1 >/dev/null
if [ $? -gt 0 ]; then
    echo "Error: jq not found"
    exit 1
fi