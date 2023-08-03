#!/bin/bash
ps aux |grep -w 'bin/gaussdb' | grep -v grep > /dev/null && chkprocess=1
if [ ! $chkprocess ]; then
  exit 0
else
  su - omm -c "cd /&& sh real.sh"
fi
