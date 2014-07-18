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
$SSH ${prefix}${nn0} "ps -ef " | egrep -i "collector|samplicate" | awk '{ print $8 }'
$SSH ${prefix}${nn0} "ps -ef " | egrep -i "logDownloader" | awk '{ print $NF }'
read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear

echo "------- COLLECTOR BINS STATUS -----------"
y=`date +%Y`
m=`date +%m`
d=`date +%d`
h=`date +%H`
$SSH ${prefix}${nn0} "/opt/hadoop/bin/hadoop fs -ls /data/netflow/$y/$m/$d/$h"

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear

echo "------- BGP DUMP's STATUS -----------"
$SSH ${prefix}${nn0} "ls -lrt /data/routing/bgp/tables/ | tail -5"
read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear

echo "------- RE IB's STATUS -----------"
$SSH ${prefix}${nn0} "$HADOOP dfs -ls /data/routing/asib | tail -2"
$SSH ${prefix}${nn0} "$HADOOP dfs -ls /data/routing/eib | tail -2"
$SSH ${prefix}${nn0} "$HADOOP dfs -ls /data/routing/merged_asib | tail -2"
read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear
