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
for i in $nn $dn $newins $rge $uip
do
  echo -n "Version on ${prefix}${i}   "
  $SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'show ver' " | grep "Build ID" || echo ""
done

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0 
clear
echo "------- CHECKING HDFS STATUS -----------"
$SSH ${prefix}${nn0} "/opt/hadoop/bin/hadoop dfsadmin -report" | head -12

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0 
clear
echo "------- CHECKING HADOOP PROCESS STATUS (NAMENODE) -----------"
$SSH ${prefix}${nn0} "ps -ef " | grep java | egrep -i "datanode|namenode|Bootstrap|jobtracker" | awk '{ print $9 }'

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0 
clear
echo "------- CHECKING INSTA STATUS -----------"
$SSH ${prefix}${ins0} "/usr/local/Calpont/bin/calpontConsole getsysteminfo"

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0 
clear

echo "------- CHECKING DRBD STATES ---------"
echo ""
echo "Verify on Namenodes..."
for i in $nn ; do
  $SSH ${prefix}${i} "drbd-overview"
done
echo ""
echo "Verify on RGE Nodes..."
for i in $rge ; do
  $SSH ${prefix}${i} "drbd-overview"
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


./verifyJobs.sh



