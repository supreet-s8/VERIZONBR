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
echo "------- CHECKING INSTA STATUS -----------"
$SSH ${prefix}${newins0} "/usr/local/Calpont/bin/calpontConsole getsysteminfo"

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0 
clear


