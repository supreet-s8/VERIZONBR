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

echo "------- CHECKING DRBD STATES ---------"
echo ""
echo "Verify on RGE Nodes..."
for i in $rge ; do
  $SSH ${prefix}${i} "drbd-overview"
done

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear

echo "----- COUNT OF INNODB & IDMAP TABLEs -----"
for i in $newins0 ; do
  echo "Working on entitynametoasprirule table"
  echo "Count(*) : `$SSH ${prefix}${i} 'psql -U postgres -d rubixdb -c \"select count(*) from entitynametoasprirule_bizreflex_vzb_unknown_cluster\" | grep [0-9] | grep -v row'`"
  echo "Working on idnamemap table"
  echo "Count(*) : `$SSH ${prefix}${i} 'psql -U postgres -d rubixdb -c \"select count(*) from idnamemap_bizreflex_vzb_unknown_cluster\" | grep [0-9] | grep -v row'`"
  echo "Working on router_idmap table"
  echo "Count(*) : `$SSH ${prefix}${i} '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=vzbr_34 -e "select count(*) from  stringid_router_idmap " | grep [0-9]'`"
  echo "Working on pop_idmap table"
  echo "Count(*) : `$SSH ${prefix}${i} '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=vzbr_34 -e "select count(*) from  stringid_pop_idmap " | grep [0-9]'`" 
done
read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear

