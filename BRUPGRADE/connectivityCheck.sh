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

SSHTIMEOUT=5
ROOTUSER='root'
SSH="/usr/bin/ssh -q -o ConnectTimeout=${SSHTIMEOUT} -l ${ROOTUSER} "
clear
echo "------- CONNECTIVITY CHECK -----------"
for i in $nn $dn $ins $rge $uip $newins
do
  hostname=`$SSH ${prefix}${i} "/bin/hostname"`
  echo -n "Version on $hostname   "
  build=`$SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'show ver' " | grep "Build ID" | awk '{print $1}'`
  if [ -z $build ]
	then
		echo "Server not reachable.."
	else
		$SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'show ver' " | grep "Build ID"	
  fi
done

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear
