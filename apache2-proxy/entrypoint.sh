#!/bin/bash

if [ "$#" -eq 0 ]; then
    export TMPDIR=/tmp
    apache2 -DFOREGROUND
else
  $@
fi
