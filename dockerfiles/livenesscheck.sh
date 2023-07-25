#!/bin/bash
ps aux | grep -w 'bin/gaussdb' | grep -v grep > /dev/null && chkprocess=1
if [ ! $chkprocess ];then
  echo 1
else
  echo 0
fi
