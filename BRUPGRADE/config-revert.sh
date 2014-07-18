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
SSH='ssh -q -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -l root ';
##########################################################################

function revertconfig {

clear
if [ $1 == "rubix" ]
then
echo "------- REVERTING CONFIG ON RUBIX & RGE NODES-----------"
for i in $uip $rge
do
  	echo "Reverting Config on ${prefix}${i}"
#	echo "Mounting ${prefix}${i} in read-write mode"
    	$SSH ${prefix}${i} "mount -o remount,rw /"
	$SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'configuration switch-to pre-BR-upgrade' 'wr mem'" > /dev/null
done
elif [ $1 == "datanodes" ]
then
echo "------- REVERTING CONFIG ON DATA NODES-----------"
for i in $dn
do
        echo "Reverting Config on ${prefix}${i}"
#       echo "Mounting ${prefix}${i} in read-write mode"
        $SSH ${prefix}${i} "mount -o remount,rw /"
        $SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'configuration switch-to pre-BR-upgrade' 'wr mem'" > /dev/null
done
elif [ $1 == "standbynn" ]
then
echo "------- REVERTING CONFIG ON STANDBY NAMENODE-----------"
for i in 108.55.163.26
do
        echo "Reverting Config on ${i}"
#       echo "Mounting ${prefix}${i} in read-write mode"
        $SSH ${i} "mount -o remount,rw /"
        $SSH ${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'configuration switch-to pre-BR-upgrade' 'wr mem'" > /dev/null
done
else [ $1 == "masternn" ]
echo "------- REVERTING CONFIG ON MASTER NAMENODE-----------"
for i in 108.55.163.56
do
        echo "Reverting Config on ${i}"
#       echo "Mounting ${prefix}${i} in read-write mode"
        $SSH ${i} "mount -o remount,rw /"
        $SSH ${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'configuration switch-to pre-BR-upgrade' 'wr mem'" > /dev/null
done
fi

}


function data-restore {

clear
if [ $1 == "rubix" ]
then
echo "------- Restoring Data on Rubix & RGE Nodes-----------"
for i in $uip $rge
do
	echo "Restoring data on ${prefix}${i}"
	$SSH ${prefix}${i} "cp /data/Backup_Pre_Upgrade/backup.tar /"
	$SSH ${prefix}${i} "cd / ; tar xf backup.tar"
done
elif [ $1 == "datanodes" ]
then
echo "------- Restoring Data on DataNodes-----------"
for i in $dn
do
	echo "Restoring data on ${prefix}${i}"
        $SSH ${prefix}${i} "cp /data/Backup_Pre_Upgrade/backup.tar /"
        $SSH ${prefix}${i} "cd / ; tar xf backup.tar"
done
elif [ $1 == "standbynn" ]
echo "------- Restoring Data on Standby NameNode-----------"
then
for i in 108.55.163.26
do
	echo "Restoring data on ${i}"
        $SSH ${i} "cp /data/Backup_Pre_Upgrade/backup.tar /"
        $SSH ${i} "cd / ; tar xf backup.tar"
done
else [ $1 == "masternn" ]
echo "------- Restoring Data on Master NameNode-----------"
for i in 108.55.163.56
do
	echo "Restoring data on ${i}"
        $SSH ${i} "cp /data/Backup_Pre_Upgrade/backup.tar /"
        $SSH ${i} "cd / ; tar xf backup.tar"
done
fi 

}

revertconfig $1
data-restore $1

#
