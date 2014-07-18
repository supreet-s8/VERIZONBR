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
for i in $nn $dn
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
for i in $nn
do
echo "------- CHECKING HADOOP PROCESS STATUS ($prefix$i) -----------"
$SSH ${prefix}${i} "ps -ef " | grep java | egrep -i "datanode|namenode|Bootstrap|jobtracker" | awk '{ print $9 }'
$SSH ${prefix}${i} "ps -ef " | egrep -i "collector|samplicate" |  grep -v grep | awk '{ print $8 }'
$SSH ${prefix}${i} "ps -ef " | egrep -i "logDownloader" |  grep -v grep | awk '{ print $NF }'
$SSH ${prefix}${i} "ps -ef " | egrep -i "re_config" |  grep -v grep |awk '{print $NF}'
$SSH ${prefix}${i} "ps -ef " | egrep -i "bgpd.conf" | grep -v grep | awk '{print $NF}'
done
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

echo "------- MAP REDUCE PARAMETERS -----------" 
for i in $nn $dn
do
  echo "Working on node ${prefix}${i}"
  $SSH ${prefix}${i} 'grep -v speculative /opt/hadoop/conf/mapred-site.xml | grep -A 1 reduce.tasks | grep -v "-"'
  $SSH ${prefix}${i} 'grep -A 1 map.tasks /opt/hadoop/conf/mapred-site.xml'
  $SSH ${prefix}${i} 'grep -A 1 timeout /opt/hadoop/conf/mapred-site.xml'
  echo " "  
done

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear
