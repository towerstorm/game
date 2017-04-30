#!/bin/bash

if [ ! "$HOSTNAME" ]; then
  echo "Required environment variable \$HOSTNAME is not set."
  exit 1
fi

(NODE_ENV=production node ./index.js &) &>> /var/log/towerstorm.log
