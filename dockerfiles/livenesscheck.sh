#!/bin/bash

if [ -e /opengauss/cluster/app/bin/instance_manual_start_* ]; then
  exit 0
fi

ps aux | grep -w 'bin/gaussdb' | grep -v grep > /dev/null && chkprocess=1
if [ ! $chkprocess ];then
  exit -1
else
  exit 0
fi
