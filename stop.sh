#!/bin/bash
# kube_dashboard=$(sudo netstat -tulpn | grep '127.0.0.1:8001' | grep '[0-9]*\/kubectl' | sed -n 's|/kubectl||p' | awk 'NF{ print $NF }')
given_port=$1
[[ -z $given_port ]] && echo "Usage: bash ./stop.sh 8001" && exit

running_port=$(lsof -i -P -n | grep "$given_port.*(LISTEN)" | awk '{print $2}')
echo $running_port

if [[ ! -z $running_port ]]; then
    kill -9 $running_port
    echo "Stopped service on port ${given_port}"
fi
