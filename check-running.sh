#!/bin/bash
# This is a good file to add to your crontab to ensure TowerStorm is always running
# You can add it by typing 'crontab -e' and then adding the line:
# * * * * * /home/towerstorm/game/check-running.sh >> /home/towerstorm/game/running-checks.log

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ $(ps aux | grep node | grep -v grep | wc -l) -ge 5 ]]; then
    echo "All apps are running"
else
    echo "ERROR: Only the following are running:"
    ps aux | grep node
    echo "Rebooting all"
    pkill node
    $DIR/start-prod.sh
fi
