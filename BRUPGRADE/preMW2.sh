#!/bin/bash

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

SSHTIMEOUT=5
ROOTUSER='root'
SSH="/usr/bin/ssh -q -o ConnectTimeout=${SSHTIMEOUT} -l ${ROOTUSER} "
clear
echo "------- CHECKING BUILD VERSION -----------"
for i in $rge $uip
do
  echo -n "Version on ${prefix}${i}   "
  $SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'show ver' " | grep "Build ID" || echo ""
done

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0 
clear

echo "----- VERIFY TOMCAT PIDs -----"
for i in $rge $uip ; do
  echo "Working on Node : ${prefix}${i}"
  echo "TOMCAT PID : `$SSH ${prefix}${i} 'ps -ef | grep tomcat | grep -v grep' | awk '{ print $2 }'`"
  echo ""
done
read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear

echo "----- VERIFY STORAGE on RGE & RUBIX nodes -----"
for i in $rge $uip ; do
  echo "Working on Node : ${prefix}${i}"
  $SSH ${prefix}${i} "blkid" | grep mapper
  $SSH ${prefix}${i} "multipath -ll | grep mpath"  
  echo " "
done
read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear

