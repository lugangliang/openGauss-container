#!/bin/bash
name=$HOSTNAME
log=`cm_ctl query -Cv|grep $name`
array=(${log//|/})
index=0
for i in ${!array[@]}
do
  if [ ${array[i]} == $name ];then
    index=$i
	break
  fi
done
status=${array[$index+4]}
if [ $status == "Normal" ];then
  echo 0
else
  echo 1
fi
 
