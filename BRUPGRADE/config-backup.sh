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
##########################################################################

function saveconfig {

clear
echo "------- CONFIG BACKUP -----------"
for i in $nn $dn $ins $rge $uip
do
#	echo "Mounting ${prefix}${i} in read-write mode"
    	$SSH ${prefix}${i} "mount -o remount,rw /"
	$SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'configuration delete pre-BR-upgrade' 'wr mem'"
  	echo "Saving Config Backup on ${prefix}${i}   "
  	$SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'configuration write to pre-BR-upgrade no-switch' 'wr mem'"
done


}


echo "------ Performing Data Backup ------"

function NN-data-bkp {

for i in $nn
do
	echo "Taking Data Backup on ${prefix}$i"
	$SSH ${prefix}${i} "mount -o remount,rw /"
	$SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade"
	$SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade/data/configs/re_configs"
	$SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade/data/configs/zebra"
	$SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade/opt/tms/java/"
	$SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade/opt/tms/bin/"
	$SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade/opt/samples/bizreflex-rubix-config/"
	$SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade/etc/iscsi/"
	$SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade/var/opt/tms/output/"
	echo "Saving df -h output in /data/Backup_Pre_Upgrade"
	$SSH ${prefix}${i} "/bin/df -h > /data/Backup_Pre_Upgrade/df"
	echo "Saving ifconfig -a output in /data/Backup_Pre_Upgrade"
	$SSH ${prefix}${i} "/sbin/ifconfig -a > /data/Backup_Pre_Upgrade/ifconfig"
	echo "Saving drbd-overview output in /data/Backup_Pre_Upgrade"
	$SSH ${prefix}${i} "/usr/sbin/drbd-overview > /data/Backup_Pre_Upgrade/drbd-overview"
	echo "Saving ps -ef output in /data/Backup_Pre_Upgrade"
	$SSH ${prefix}${i} "/bin/ps -ef  > /data/Backup_Pre_Upgrade/ps"
	echo "Saving hadoop dfsadmin -report output in /data/Backup_Pre_Upgrade"
	$SSH ${prefix}${i} "/opt/hadoop/bin/hadoop dfsadmin -report > /data/Backup_Pre_Upgrade/hadoop-report"
	$SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'show running full' > /data/Backup_Pre_Upgrade/full-runn-config"
	echo "Copy /etc/multipath.conf to /data/Backup_Pre_Upgrade/var/opt/tms/output/multipath.conf"
	$SSH ${prefix}${i} "/bin/cp /etc/multipath.conf /data/Backup_Pre_Upgrade/var/opt/tms/output/"
	echo "Copy /data/IBS to /data/Backup_Pre_Upgrade/data/IBS"
	$SSH ${prefix}${i} "/bin/cp -r /data/IBS /data/Backup_Pre_Upgrade/data/IBS"
	echo "Copy /data/configs/hadoop_conf to /data/Backup_Pre_Upgrade/data/configs/hadoop_conf"
	$SSH ${prefix}${i} "/bin/cp -r /data/configs/hadoop_conf /data/Backup_Pre_Upgrade/data/configs/hadoop_conf"
	echo "Copy /opt/samples/bizreflex-rubix-config/logdownloader/ to /data/Backup_Pre_Upgrade/opt/samples/bizreflex-rubix-config/"
	$SSH ${prefix}${i} "/bin/cp -r /opt/samples/bizreflex-rubix-config/logdownloader/ /data/Backup_Pre_Upgrade/opt/samples/bizreflex-rubix-config/"
	echo "Copy /data/configs/samplicate.cfg to /data/Backup_Pre_Upgrade/data/configs/samplicate.cfg"
	$SSH ${prefix}${i} "/bin/cp /data/configs/samplicate.cfg /data/Backup_Pre_Upgrade/data/configs/samplicate.cfg"
	echo "Copy /data/configs/re_configs/re_config_updated.xml to /data/Backup_Pre_Upgrade/data/configs/re_configs/re_config_updated.xml"
	$SSH ${prefix}${i} "/bin/cp /data/configs/re_configs/re_config_updated.xml /data/Backup_Pre_Upgrade/data/configs/re_configs/re_config_updated.xml"
	echo "Copy /data/configs/re_configs/system.xml to /data/Backup_Pre_Upgrade/data/configs/re_configs/system.xml"
	$SSH ${prefix}${i} "/bin/cp /data/configs/re_configs/system.xml /data/Backup_Pre_Upgrade/data/configs/re_configs/system.xml"
	echo "Copy /data/configs/zebra/bgpd.conf to /data/Backup_Pre_Upgrade/data/configs/zebra/bgpd.conf"
	$SSH ${prefix}${i} "/bin/cp /data/configs/zebra/bgpd.conf /data/Backup_Pre_Upgrade/data/configs/zebra/bgpd.conf"
	echo "Copy /etc/iscsi/initiatorname.iscsi to /data/Backup_Pre_Upgrade/etc/iscsi/initiatorname.iscsi"
	$SSH ${prefix}${i} "/bin/cp /etc/iscsi/initiatorname.iscsi /data/Backup_Pre_Upgrade/etc/iscsi/initiatorname.iscsi"
	echo "Copy /opt/tms/java/CubeCreator.jar to /data/Backup_Pre_Upgrade/opt/tms/java/"
	$SSH ${prefix}${i} "/bin/cp /opt/tms/java/CubeCreator.jar /data/Backup_Pre_Upgrade/opt/tms/java/"
	echo "Copy /opt/tms/bin/re to /data/Backup_Pre_Upgrade/opt/tms/bin/"
	$SSH ${prefix}${i} "/bin/cp /opt/tms/bin/re /data/Backup_Pre_Upgrade/opt/tms/bin/"
	echo "Copy /data/routing/aib from Hadoop to /data/Backup_Pre_Upgrade/aib"
	$SSH ${prefix}${i} "/opt/hadoop/bin/hadoop dfs -get /data/routing/aib /data/Backup_Pre_Upgrade/"
	echo "Copy /data/routing/routerSampling from Hadoop to /data/Backup_Pre_Upgrade/routerSampling"
	$SSH ${prefix}${i} "/opt/hadoop/bin/hadoop dfs -get /data/routing/routerSampling /data/Backup_Pre_Upgrade/"
	echo "Copy /data/routing/sib from Hadoop to /data/Backup_Pre_Upgrade/sib"
	$SSH ${prefix}${i} "/opt/hadoop/bin/hadoop dfs -get /data/routing/sib /data/Backup_Pre_Upgrade/"
	echo "Copy /data/routing/gleaning from Hadoop to /data/Backup_Pre_Upgrade/gleaning"
	$SSH ${prefix}${i} "/opt/hadoop/bin/hadoop dfs -get /data/routing/gleaning /data/Backup_Pre_Upgrade/"
	echo "Copy /data/_BizreflexCubes/RouterNameToID/routertoidmap from Hadoop to /data/Backup_Pre_Upgrade/routertoidmap"
	$SSH ${prefix}${i} "/opt/hadoop/bin/hadoop dfs -get /data/_BizreflexCubes/RouterNameToID/routertoidmap /data/Backup_Pre_Upgrade/"
	echo "Copy /data/_BizreflexCubes/Gleaning/gleaning from Hadoop to /data/Backup_Pre_Upgrade/Biz_gleaning"
	$SSH ${prefix}${i} "/opt/hadoop/bin/hadoop dfs -get /data/_BizreflexCubes/Gleaning/gleaning /data/Backup_Pre_Upgrade/Biz_gleaning"
	echo "Copy /data/_BizreflexCubes/WhiteAsList/whiteaslist from Hadoop to /data/Backup_Pre_Upgrade/whiteaslist"
	$SSH ${prefix}${i} "/opt/hadoop/bin/hadoop dfs -get /data/_BizreflexCubes/WhiteAsList/whiteaslist /data/Backup_Pre_Upgrade/"
#	$SSH ${prefix}${i} 'cd /var/opt/tms && /bin/mv sysdumps /data/ && /bin/ln -s /data/sysdumps'
	echo "Creating tar file"
	$SSH ${prefix}${i} "cd /data/Backup_Pre_Upgrade/ ; tar cf backup.tar *"
done

}


function DN-data-bkp {

for i in $dn
do

	echo "Taking Data Backup on ${prefix}$i :"
        $SSH ${prefix}${i} "mount -o remount,rw /"
        $SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade"
	$SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade/data/configs/"
	$SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade/opt/tms/java/"
	$SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade/etc/iscsi/"
        $SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade/var/opt/tms/output/"
        echo "Saving df -h output in /data/Backup_Pre_Upgrade"
	$SSH ${prefix}${i} "/bin/df -h > /data/Backup_Pre_Upgrade/df"
	echo "Saving ifconfig -a output in /data/Backup_Pre_Upgrade"
        $SSH ${prefix}${i} "/sbin/ifconfig -a > /data/Backup_Pre_Upgrade/ifconfig"
	$SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'show running full' > /data/Backup_Pre_Upgrade/full-runn-config"
        echo "Copy /etc/multipath.conf to /data/Backup_Pre_Upgrade/var/opt/tms/output/multipath.conf"
	$SSH ${prefix}${i} "/bin/cp /etc/multipath.conf /data/Backup_Pre_Upgrade/var/opt/tms/output/"
	echo "Saving mount output in /data/Backup_Pre_Upgrade"
	$SSH ${prefix}${i} "/bin/mount > /data/Backup_Pre_Upgrade/mount"
	echo "Saving blkid output in /data/Backup_Pre_Upgrade"
	$SSH ${prefix}${i} "/sbin/blkid > /data/Backup_Pre_Upgrade/blkid"
	echo "Saving fdisk -l output in /data/Backup_Pre_Upgrade"
	$SSH ${prefix}${i} "/sbin/fdisk -l > /data/Backup_Pre_Upgrade/fdisk" 2> /dev/null
	echo "Saving multipath -ll output in /data/Backup_Pre_Upgrade"
	$SSH ${prefix}${i} "/sbin/multipath -ll > /data/Backup_Pre_Upgrade/multipath-ll"
	echo "Saving ps -aef output in /data/Backup_Pre_Upgrade"
	$SSH ${prefix}${i} "/bin/ps -aef > /data/Backup_Pre_Upgrade/ps"
	echo "Copy /etc/multipath/bindings to /data/Backup_Pre_Upgrade/var/opt/tms/output/bindings"
	$SSH ${prefix}${i} "/bin/cp /etc/multipath/bindings /data/Backup_Pre_Upgrade/var/opt/tms/output/"
	echo "Copy /data/configs/hadoop_conf to /data/Backup_Pre_Upgrade/data/configs/hadoop_conf"
	$SSH ${prefix}${i} "/bin/cp -r /data/configs/hadoop_conf /data/Backup_Pre_Upgrade/data/configs/"
	echo "Copy /opt/tms/java/CubeCreator.jar to /data/Backup_Pre_Upgrade/opt/tms/java/CubeCreator.jar"
	$SSH ${prefix}${i} "/bin/cp /opt/tms/java/CubeCreator.jar /data/Backup_Pre_Upgrade/opt/tms/java/"
#	$SSH ${prefix}${i} 'cd /var/opt/tms && /bin/mv snapshots /data/ && /bin/ln -s /data/snapshots'
#        $SSH ${prefix}${i} 'cd /var/opt/tms && /bin/mv sysdumps /data/ && /bin/ln -s /data/sysdumps'
	$SSH ${prefix}${i} "cd /data/Backup_Pre_Upgrade/ ; tar cf backup.tar *"
done
}


function RGE-data-bkp {

for i in $rge
do
	echo "Taking Data Backup on ${prefix}$i :"
        $SSH ${prefix}${i} "mount -o remount,rw /"
        $SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade"
	$SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade/opt/tms/"
	$SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade/opt/samples/bizreflex-rubix-config/"
	$SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade/data/apache-tomcat/"
	echo "Saving df -h output in /data/Backup_Pre_Upgrade"
	$SSH ${prefix}${i} "/bin/df -h > /data/Backup_Pre_Upgrade/df"
	echo "Saving ifconfig -a output in /data/Backup_Pre_Upgrade"
        $SSH ${prefix}${i} "/sbin/ifconfig -a > /data/Backup_Pre_Upgrade/ifconfig"
        $SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'show running full' > /data/Backup_Pre_Upgrade/full-runn-config"
	echo "Saving mount output in /data/Backup_Pre_Upgrade"
        $SSH ${prefix}${i} "/bin/mount > /data/Backup_Pre_Upgrade/mount"
	echo "Saving ps -aef output in /data/Backup_Pre_Upgrade"
        $SSH ${prefix}${i} "/bin/ps -aef  > /data/Backup_Pre_Upgrade/ps"
	echo "Copying /data/apache-tomcat/apache-tomcat-7.0.27_as701 to /data/Backup_Pre_Upgrade/data/apache-tomcat/apache-tomcat-7.0.27_as701"
	$SSH ${prefix}${i} "/bin/cp -r /data/apache-tomcat/apache-tomcat-7.0.27_as701 /data/Backup_Pre_Upgrade/data/apache-tomcat/"
	echo "Copying /opt/tms/rge-bizreflex3.0_as701/ to /data/Backup_Pre_Upgrade/opt/tms/rge-bizreflex3.0_as701"
        $SSH ${prefix}${i} "/bin/cp -r /opt/tms/rge-bizreflex3.0_as701/ /data/Backup_Pre_Upgrade/opt/tms/"
	echo "Copying /opt/samples/bizreflex-rubix-config/rubix to /data/Backup_Pre_Upgrade/opt/samples/bizreflex-rubix-config/rubix"
        $SSH ${prefix}${i} "/bin/cp -r /opt/samples/bizreflex-rubix-config/rubix /data/Backup_Pre_Upgrade/opt/samples/bizreflex-rubix-config/"
	echo "Saving drbd-overview output in /data/Backup_Pre_Upgrade/"
	$SSH ${prefix}${i} "/usr/sbin/drbd-overview > /data/Backup_Pre_Upgrade/drbd-overview"
#	$SSH ${prefix}${i} 'cd /var/opt/tms && /bin/mv snapshots /data/ && /bin/ln -s /data/snapshots'
#        $SSH ${prefix}${i} 'cd /var/opt/tms && /bin/mv sysdumps /data/ && /bin/ln -s /data/sysdumps'
	$SSH ${prefix}${i} "cd /data/Backup_Pre_Upgrade/ ; tar cf backup.tar *"

done


}


function ins-data-bkp {

for i in $ins
do
	echo "Taking Data Backup on ${prefix}$i :"
        $SSH ${prefix}${i} "mount -o remount,rw /"
        $SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade"
	echo "Saving df output in /data/Backup_Pre_Upgrade"
        $SSH ${prefix}${i} "/bin/df -h > /data/Backup_Pre_Upgrade/df"
	echo "Saving ifconfig -a output in /data/Backup_Pre_Upgrade"
        $SSH ${prefix}${i} "/sbin/ifconfig -a > /data/Backup_Pre_Upgrade/ifconfig"
        $SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'show running full' > /data/Backup_Pre_Upgrade/full-runn-config"
        $SSH ${prefix}${i} "/bin/cp /etc/multipath.conf /data/Backup_Pre_Upgrade/"
        $SSH ${prefix}${i} "/bin/mount > /data/Backup_Pre_Upgrade/mount"
        $SSH ${prefix}${i} "/sbin/fdisk -l > /data/Backup_Pre_Upgrade/fdisk" 2> /dev/null
        $SSH ${prefix}${i} "/sbin/multipath -ll > /data/Backup_Pre_Upgrade/multipath-ll"
        $SSH ${prefix}${i} "/bin/ps -ef | grep insta > /data/Backup_Pre_Upgrade/ps-insta"
        $SSH ${prefix}${i} "/bin/ps -ef | grep gmountd > /data/Backup_Pre_Upgrade/ps-gmountd"
	$SSH ${prefix}${i} "/usr/local/Calpont/bin/calpontConsole getsysteminfo y > /data/Backup_Pre_Upgrade/cc-getsysteminfo"
	$SSH ${prefix}${i} "/bin/cp /etc/multipath/bindings /data/Backup_Pre_Upgrade/"
#	$SSH ${prefix}${i} 'cd /var/opt/tms && /bin/mv snapshots /data/ && /bin/ln -s /data/snapshots'
#        $SSH ${prefix}${i} 'cd /var/opt/tms && /bin/mv sysdumps /data/ && /bin/ln -s /data/sysdumps'
	$SSH ${prefix}${i} "cd /data/Backup_Pre_Upgrade/ ; tar cf backup.tar *"

done
}


function UI-data-bkp {

for i in $olduip
do
	echo "Taking Data Backup on ${prefix}$i :"
        $SSH ${prefix}${i} "mount -o remount,rw /"
        $SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade"
        $SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade/opt/tms/"
        $SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade/opt/samples/bizreflex-rubix-config/"
        $SSH ${prefix}${i} "/bin/mkdir -p /data/Backup_Pre_Upgrade/data/apache-tomcat/"
	echo "Saving df -h output in /data/Backup_Pre_Upgrade"
	$SSH ${prefix}${i} "/bin/df -h > /data/Backup_Pre_Upgrade/df"
	echo "Saving ifconfig -a output in /data/Backup_Pre_Upgrade"
        $SSH ${prefix}${i} "/sbin/ifconfig -a > /data/Backup_Pre_Upgrade/ifconfig"
        $SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'show running full' > /data/Backup_Pre_Upgrade/full-runn-config"
	echo "Saving mount output in /data/Backup_Pre_Upgrade"
	$SSH ${prefix}${i} "/bin/mount > /data/Backup_Pre_Upgrade/mount"
	echo "Saving ps -aef output in /data/Backup_Pre_Upgrade"
	$SSH ${prefix}${i} "/bin/ps -aef > /data/Backup_Pre_Upgrade/ps"
	$SSH ${prefix}${i} "> /data/apache-tomcat/apache-tomcat-7.0.27/bin/bizreflex.log"
	echo "Copying /data/apache-tomcat/apache-tomcat-7.0.27 to /data/Backup_Pre_Upgrade/data/apache-tomcat/apache-tomcat-7.0.27"
	$SSH ${prefix}${i} "/bin/cp -r /data/apache-tomcat/apache-tomcat-7.0.27 /data/Backup_Pre_Upgrade/data/apache-tomcat/"
	echo "Copying /opt/tms/bizreflex-bizreflex3.0/ to /data/Backup_Pre_Upgrade/opt/tms/bizreflex-bizreflex3.0/"
	$SSH ${prefix}${i} "/bin/cp -r /opt/tms/bizreflex-bizreflex3.0/ /data/Backup_Pre_Upgrade/opt/tms/"
#	$SSH ${prefix}${i} 'cd /var/opt/tms && /bin/mv snapshots /data/ && /bin/ln -s /data/snapshots'
#        $SSH ${prefix}${i} 'cd /var/opt/tms && /bin/mv sysdumps /data/ && /bin/ln -s /data/sysdumps'
	$SSH ${prefix}${i} "cd /data/Backup_Pre_Upgrade/ ; tar cf backup.tar *"
done
}



saveconfig
NN-data-bkp
DN-data-bkp
RGE-data-bkp
#ins-data-bkp
UI-data-bkp
echo ""
echo "Proceed to backup the storage configuration... "
./bkpStorage.sh
echo ""
echo "Proceed to backup system files... "
./backUp.sh

#
