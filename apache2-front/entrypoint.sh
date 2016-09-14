#!/bin/bash

# writing history of all container start for volume demo purpose
mkdir -p /data/
echo "starting at $(date)" >> /data/history
chmod 666 /data/history
cat /data/history

if [ "$#" -eq 0 ]; then
    export TMPDIR=/tmp
    rm -f /var/run/apache2/apache2.pid
    apache2 -DFOREGROUND
else
  $@
fi
