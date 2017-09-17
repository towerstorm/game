#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! "$HOSTNAME" ]; then
  echo "Required environment variable \$HOSTNAME is not set."
  exit 1
fi

(NODE_ENV=production node $DIR/index.js &) &>> /var/log/towerstorm.log
