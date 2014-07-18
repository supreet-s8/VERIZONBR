#!/bin/bash
source env.sh

IPS="$PWD/IP.sh"
function getHosts()
{
  source ${IPS}
  if [[ $? -ne 0 ]]
  then
    printf "Unable to read source for IP Address List\nCannot continue"
    exit 255
  fi
}
# Get Hosts
getHosts

clear

echo "------- VERIFYING JOBS ---------"

echo " ---- Verifying on Master Namenode ---- "
for i in $nn0 ; do
  $SSH ${prefix}${i} '/opt/tps/bin/pmx.py subshell oozie show coordinator RUNNING jobs' | awk '{ print $2 }' | grep -v ID | grep -v Jobs | grep -v "^$" | sort
  $SSH ${prefix}${i} '/opt/tps/bin/pmx.py subshell oozie show coordinator PREP jobs' | awk '{ print $2 }' | grep -v ID | grep -v Jobs | grep -v "^$" | sort
done


