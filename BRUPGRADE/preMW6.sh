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


./verifyJobs.sh

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear

echo "----- VERIFY JOB O/P's -----"
for i in $nn0 ; do
  $SSH ${prefix}${i} "$HADOOP dfs -du /data/BR_OUT/oozie/PrefixJob/2014/06/"
  $SSH ${prefix}${i} "$HADOOP dfs -du /data/BR_OUT/oozie/PrefixJob/2014/07/"
  $SSH ${prefix}${i} "$HADOOP dfs -du /data/BR_OUT/oozie/MasterJob/2014/07/"
  $SSH ${prefix}${i} "$HADOOP dfs -du /data/BR_OUT/oozie/BizRulesJob/2014/06/"
  $SSH ${prefix}${i} "$HADOOP dfs -du /data/BR_OUT/oozie/BizRulesJob/2014/07/"
  $SSH ${prefix}${i} "multipath -ll | grep dbroot"  
  echo " "
done
read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear

echo "----- INSTA BIN METATABLE -----"
$SSH ${prefix}${newins0} '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=vzbr_34 -e "select * from bin_metatable " '

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear

