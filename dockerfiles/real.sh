#!/bin/bash
name=$HOSTNAME
log=`cm_ctl query -Cv|grep $name`
array=(${log//|/})
index=0
for i in ${!array[@]}
do
  if [ "${array[i]}"x == "$name"x ];then
    index=$i
    break
  fi
done
status=${array[$index+4]}
if [ "$status"x == "Normal"x ];then
  exit 0
else
  exit -1
fi
 
