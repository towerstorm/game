#!/bin/bash

if [[ $(ps aux | grep node | grep -v grep | wc -l) -ge 5 ]]; then
    echo "All apps are running"
else
    echo "ERROR: Only the following are running:"
    sudo ps aux | grep node
    echo "Rebooting all"
    sudo pkill node
    ~/game/start-prod.sh
fi