#!/bin/bash

source env.sh

function ssh_init
{
  if [[ ! -e /home/`whoami`/.ssh/id_rsa.pub ]] 
  then
    echo "No existing ssh key pair found, generating new...."
    /usr/bin/ssh-keygen -f /home/`whoami`/.ssh/id_rsa -q 
  fi
}



function share_sshkey
{
  echo "Copying your SSH Key to remote host $1"
  ssh_init
  cat /home/`whoami`/.ssh/id_rsa.pub | ssh -l root $1 "umask 077 ; test -d .ssh || mkdir .ssh ; cat >> .ssh/authorized_keys2"
}

function share_sshkey_TM
{
  src=$1
  dst=$2
  $SSH $src '/usr/bin/ssh-keygen -N "" -t rsa -f /var/home/root/.ssh/id_rsa'
  KEY=`$SSH $src "cat /var/home/root/.ssh/id_rsa.pub"`
  echo -n "/opt/tms/bin/cli -t 'en' 'configure terminal' 'ssh client user admin authorized-key sshv2 \"${KEY}\"' " > sshcmdfile
  /usr/bin/ssh -l root $dst $(<sshcmdfile)
  $SSH $dst "/opt/tms/bin/cli -t 'en' 'conf t' 'wr me'"
}

function xfer_install_image
{
  imagepath=$1
  host=$2
  if [[ -r ${imagepath} ]]
  then
    scp -q ${imagepath} root@$host:/tmp/
  else
    echo "Image: ${imagepath} not found"
  fi
}

function fetch_image
{
  image_url=$1
  host=$2
  image=`basename ${image_url}`
  $SSH ${host} "/opt/tms/bin/cli -t 'en' 'conf terminal' 'image fetch ${image_url}' "
  $SSH ${host} "/opt/tms/bin/cli -t 'en' 'conf terminal' 'show images'" | grep -q ${image} && echo "Image $image copied succesfully" || echo "Image $image not copied succesfully"
}

function sync_hwclock 
{
  echo "Syncing Hardware Clock on $1"
  $SSH $1 "mount -o remount,rw / && [[ -L /dev/rtc ]] || ln -s /dev/rtc0 /dev/rtc"
  $SSH $1 "hwclock --systohc && hwclock --show"
  if [[ $? -ne 0 ]]
  then
    printf "Unable to setup HW clock on $1\n"
  fi
}

function install_image
{
  image=$1
  host=$2
  $SSH ${host} "/opt/tms/bin/cli -t 'en' 'conf terminal' 'show images'" | grep -q ${image} && available=1 || available=0
  if [[ ${available} -eq 1 ]]
  then
    $SSH ${host} "/opt/tms/bin/cli -t 'en' 'conf terminal' 'image install ${image} location 2 progress no-track verify ignore-sig' " &
    echo "Image ${image} install under progress on host ${host}" 
  else 
    echo "Image: ${image} not available on ${host}"
  fi
}

function verifyProgress 
{
  remaining="0"
  for host ; do
    echo -n "Checking progress on ${host}......"
    $SSH ${host} "/opt/tms/bin/cli -t 'en' 'conf term' 'show images' " | grep "Image install in progress"
    if [[ $? -ne 0 ]]
    then
      echo "Install Complete..."
    else
      remaining="1"
    fi
  done
  if [[ ${remaining} -eq "0" ]]
  then
    echo "All nodes completed image install" ;
  fi

}

#### Stop Jobs ####

function stopjobs {

echo "Stopping Jobs on Namenode"
$SSH $gdsvzbcolvip "$PMX subshell oozie stop jobname all" | grep "stopped job successfully"
echo "Waiting 5 seconds for jobs to terminate"
sleep 5
echo "Terminating any remnant jobs....."
for job in `$SSH $gdsvzbcolvip "$PMX subshell oozie show coordinator RUNNING jobs" | grep -v "^No Jobs" | grep -v "Console" | grep -v "^-" | awk {'print $1'}`; do echo -e "\tStopping remnant job $job" ; $SSH $gdsvzbcolvip "$PMX subshell oozie stop jobid $job" ; done
echo "Verifying that no jobs exist on the namenode"
$SSH $gdsvzbcolvip "$PMX subshell oozie show coordinator RUNNING jobs"
$SSH $gdsvzbcolvip "$PMX subshell oozie show coordinator PREP jobs"

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
clear

}

#### last successful iteration timestamp for master job ####

function timestamp {

echo "select the timestamp which is lowest among the two jobs master_job and second_job"
time_master=`$SSH $gdsvzbcolvip "$HADOOP dfs -cat /data/master_job/done.txt"`
tm=`echo $time_master|sed 's/[A-Z]/ /g'`
timestamp_master=`date +%s -d"$tm"`
time_second=`$SSH $gdsvzbcolvip "$HADOOP dfs -cat /data/second_job/done.txt"`
ts=`echo $time_second|sed 's/[A-Z]/ /g'`
timestamp_second=`date +%s -d"$ts"`

if [[ -z "$timestamp_second" ]]
then
	final_time=$time_master
        echo "We'll be using $time_master timestamp as the end-time for the temporary upgrade jobs, and as the startTime of jobs after upgrade."
elif [[ "$timestamp_master" -gt "$timestamp_second" ]]
then
	final_time=$time_second
	echo "We'll be using $time_second timestamp as the end-time for the temporary upgrade jobs, and as the startTime of jobs after upgrade."
else
	final_time=$time_master
	echo "We'll be using $time_master timestamp as the end-time for the temporary upgrade jobs, and as the startTime of jobs after upgrade."
fi
echo $final_time > $PWD/jobtime.txt

}


########  Take Backup of Innodb data #########

function innodb_backup {

echo "------- Backup of Innodb data -----------"
$SSH $gdsvzbinsvip '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=rubix3 -e "select * from  asblacklistrule_bizreflex_701 " > /tmp/old_asblack_data.txt; sed -i 1d /tmp/old_asblack_data.txt; sed -i "s/\t/,/g" /tmp/old_asblack_data.txt'
$SSH $gdsvzbinsvip '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=rubix3 -e "select * from  asprospectrule_bizreflex_701 " > /tmp/old_asprspct_data.txt; sed -i 1d /tmp/old_asprspct_data.txt; sed -i "s/\t/,/g" /tmp/old_asprspct_data.txt'
$SSH $gdsvzbinsvip '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=rubix3 -e "select * from  entitynametoasprirule_bizreflex_701 " > /tmp/old_entity_data.txt; sed -i 1d /tmp/old_entity_data.txt; sed -i "s/\t/,/g" /tmp/old_entity_data.txt'
$SSH $gdsvzbinsvip '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=rubix3 -e "select * from filter_bizreflex_701 " > /tmp/old_filter_data.txt;sed -i 1d /tmp/old_filter_data.txt;sed -i "s/\t/,/g" /tmp/old_filter_data.txt'
$SSH $gdsvzbinsvip '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=rubix3 -e "select * from idnamemap_bizreflex_701 " > /tmp/old_idnamemap_data.txt;sed -i 1d /tmp/old_idnamemap_data.txt;sed -i "s/\t/,/g" /tmp/old_idnamemap_data.txt'
$SSH $gdsvzbinsvip '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=rubix3 -e "select * from user " > /tmp/old_user_data.txt;sed -i 1d /tmp/old_user_data.txt;sed -i "s/\t/,/g" /tmp/old_user_data.txt'
$SSH $gdsvzbinsvip '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=rubix3 -e "select * from user_role " > /tmp/old_user_role_data.txt;sed -i 1d /tmp/old_user_role_data.txt;sed -i "s/\t/,/g" /tmp/old_user_role_data.txt'
$SSH $gdsvzbinsvip '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=rubix3 -e "select * from user_group " > /tmp/old_user_grp_data.txt;sed -i 1d /tmp/old_user_grp_data.txt;sed -i "s/\t/,/g" /tmp/old_user_grp_data.txt'
$SSH $gdsvzbinsvip '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=rubix3 -e "select * from group_role " > /tmp/old_grp_role_data.txt;sed -i 1d /tmp/old_grp_role_data.txt;sed -i "s/\t/,/g" /tmp/old_grp_role_data.txt'
$SSH $gdsvzbinsvip '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=rubix3 -e "select * from groupinfo " > /tmp/old_grpinfo_data.txt;sed -i 1d /tmp/old_grpinfo_data.txt;sed -i "s/\t/,/g" /tmp/old_grpinfo_data.txt'
$SSH $gdsvzbinsvip '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=rubix3 -e "select * from modulepermissiondata " > /tmp/old_module_data.txt;sed -i 1d /tmp/old_module_data.txt;sed -i "s/\t/,/g" /tmp/old_module_data.txt'
$SSH $gdsvzbinsvip '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=rubix3 -e "select * from role " > /tmp/old_role_data.txt;sed -i 1d /tmp/old_role_data.txt;sed -i "s/\t/,/g" /tmp/old_role_data.txt'
$SSH $gdsvzbinsvip '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=rubix3 -e "select * from role_modules " > /tmp/old_rolemodule_data.txt;sed -i 1d /tmp/old_rolemodule_data.txt;sed -i "s/\t/,/g" /tmp/old_rolemodule_data.txt'

$SSH $gdsvzbinsvip "mkdir -p /data/BackupFiles/"
$SSH $gdsvzbinsvip "mv /tmp/old*.txt /data/BackupFiles/"

standby=`$SSH $gdsvzbinsvip "/opt/tms/bin/cli -t 'en' 'conf t' 'sh cluster global brief' | grep -i standby|tail -1"|awk '{print \$NF}'`
echo "------- Copying innodb backup to standby node ${standby} -------"
scp -qr root@${gdsvzbinsvip}:/data/BackupFiles root@${standby}:/data/

scp -qr root@${gdsvzbinsvip}:/data/BackupFiles admin@${gdsvzbinsnew1}:/data/
scp -qr root@${gdsvzbinsvip}:/data/BackupFiles admin@${gdsvzbinsnew2}:/data/

}

######## patch on data nodes #########

function applypatch_dn {

clear
echo "------- INSTALLING PATCH ON ALL DATA NODES -----------"
for i in $gdsvzbcmp1 $gdsvzbcmp2 $gdsvzbcmp3 $gdsvzbcmp4 $gdsvzbcmp5 $gdsvzbcmp6 $gdsvzbcmp7 $gdsvzbcmp8 $gdsvzbcmp9 $gdsvzbcmp10 $gdsvzbcmp11 $gdsvzbcmp12 $gdsvzbcmp13
do
    scp -q $PWD/patches/bizreflex3.4.rc2.p1.tgz root@${i}:/tmp
    scp -q $PWD/patches/bizreflex3.4.rc2.p2.tgz root@${i}:/tmp
    scp -q $PWD/patches/bizreflex3.4.rc2.p3.tgz root@${i}:/tmp
    scp -q $PWD/patches/bizreflex3.4.rc2.upgradeBR3.2.p1.tgz root@${i}:/tmp
    scp -q $PWD/patches/bizreflex3.4.rc2.p9.tgz root@${i}:/tmp

    echo "Mounting ${i} in read-write mode"
    $SSH ${i} "mount -o remount,rw /"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.p1.tgz"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.p1" | grep -i success
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.p2.tgz"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.p2" | grep -i success
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.p3.tgz"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.p3" | grep -i success
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.upgradeBR3.2.p1.tgz"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.upgradeBR3.2.p1" | grep -i success
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.p9.tgz"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.p9" | grep -i success
    echo "-------------- Done --------------------------"
    echo ""
done

}

######## patch on name nodes #########

function applypatch_nn {

i=$1
clear
echo "------- INSTALLING PATCH ON NAME NODE ${i} -----------"
scp -q $PWD/patches/bizreflex3.4.rc2.p1.tgz root@${i}:/tmp
scp -q $PWD/patches/bizreflex3.4.rc2.p2.tgz root@${i}:/tmp
scp -q $PWD/patches/bizreflex3.4.rc2.p3.tgz root@${i}:/tmp
scp -q $PWD/patches/bizreflex3.4.rc2.upgradeBR3.2.p1.tgz root@${i}:/tmp
scp -q $PWD/patches/bizreflex3.4.rc2.p9.tgz root@${i}:/tmp

echo "Mounting ${i} in read-write mode"
$SSH ${i} "mount -o remount,rw /"
$SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.p1.tgz"
$SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.p1" | grep -i success
$SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.p2.tgz"
$SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.p2" | grep -i success
$SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.p3.tgz"
$SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.p3" | grep -i success
$SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.upgradeBR3.2.p1.tgz"
$SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.upgradeBR3.2.p1" | grep -i success
$SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.p9.tgz"
$SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.p9" | grep -i success
echo "-------------- Done --------------------------"
echo ""

}

######## patch on rubix ######## 

function applypatch_rubix {

clear
echo "------- INSTALLING PATCH ON ALL RUBIX NODES -----------"
for i in $gdsvzbrub1 $gdsvzbrub2 $gdsvzbrub3 $gdsvzbrub4 $gdsvzbrub5 $gdsvzbrub6
do
    scp -q $PWD/patches/bizreflex3.4.rc2.p2.tgz root@${i}:/tmp
    scp -q $PWD/patches/bizreflex3.4.rc2.p3.tgz root@${i}:/tmp
    scp -q $PWD/patches/bizreflex3.4.rc2.p4.tgz root@${i}:/tmp 
    scp -q $PWD/patches/bizreflex3.4.rc2.p5.tgz root@${i}:/tmp 
    scp -q $PWD/patches/bizreflex3.4.rc2.vzb.180.days.support.p1.tgz root@${i}:/tmp
    scp -q $PWD/patches/bizreflex3.4.rc2.vzb.180.days.support.p2.tgz root@${i}:/tmp
    echo "Mounting ${i} in read-write mode"
    $SSH ${i} "mount -o remount,rw /"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.p2.tgz"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.p2" | grep -i success
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.p3.tgz"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.p3" | grep -i success
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.p4.tgz"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.p4" | grep -i success
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.p5.tgz"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.p5" | grep -i success
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.vzb.180.days.support.p1.tgz"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.vzb.180.days.support.p1" | grep -i success
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.vzb.180.days.support.p2.tgz"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.vzb.180.days.support.p2" | grep -i success
    echo "-------------- Done --------------------------"
    echo ""
done

}

########  post upgrade rubix ######## 

function post_upgrade_conf_rubix {

echo "-------- Configuration of RUBIX nodes  -------"
echo " "

for i in $gdsvzbrub1 $gdsvzbrub2 $gdsvzbrub3 $gdsvzbrub4 $gdsvzbrub5 $gdsvzbrub6
do
   $SSH $i "mount -o remount,rw /"
   scp -q $PWD/vzbrub_$i.tgz root@${i}:/
   $SSH $i "/opt/tps/bin/pmx.py register iscsi"
   tps_fs $i 2
   $SSH $i "cd / ; tar -xzf vzbrub_$i.tgz"
   $SSH $i "$CLI -t 'en' 'conf t' 'pm process rubix terminate'"
   $SSH $i 'echo "MaxStartups 20" >> /var/opt/tms/output/sshd_config'
   $SSH $i "$CLI -t 'en' 'conf t' 'pm process sshd restart'"
   rubix_conf $i
   $SSH $i 'cd /opt/tms/bizreflex-bizreflex3.3/WEB-INF/classes/ ; /usr/bin/python TreeCacheEntries.py --60m="1h:336;3h:496;1d:124" --1h="1h:23;3h:0;1d:0;7d:0;1M:0" --1d="1d:1;7d:0;1M:0" --1w="7d:1;1M:0" --1M="1M:1" --5m="5m:35712;1h:0;3h:0;1d:0;7d:0;1M:0"'
   $SSH $i "/bin/mkdir -p /data/rubix/vzbrubix"
   $SSH $1 "/bin/touch /data/rubix/vzbrubix/disk_mounted"
   #$SSH $i "mkdir -p /data/configs/EntityConfig"
   $SSH $i "/bin/cp /data/configs/EntityConfig/portDefinition.csv /data/configs/EntityConfig/portDefinition.csv_orig"
   $SSH $i "/bin/cp /data/configs/EntityConfig/popDistance.csv /data/configs/EntityConfig/popDistance.csv_orig"
   $SSH $i "rm -rf /data/apache-tomcat/apache-tomcat-7.0.27"
   $SSH $i "cd /data/apache-tomcat/ ; gzip -dc tomcat.tar.gz |tar xf -"
   $SSH $i "chmod +x /data/configs/EntityConfig/create_port_files.sh ; cd /data/configs/EntityConfig/ ; ./create_port_files.sh"
   $SSH $i "/bin/cat /data/configs/EntityConfig/popDefinition.csv_orig"|awk -F, -v OFS="," '{ "echo \""$1"\"|tr \"-\" \"_\""|getline $1}7'|awk -F, -v OFS="," '{ "echo \""$2"\"|tr \"-\" \" \""|getline $2}7'|awk -F, -v OFS="," '{ "echo \""$3"\"|tr \"-\" \" \""|getline $3}7' > popDefinition.csv
   scp popDefinition.csv root@$i:/data/configs/EntityConfig/
   $SSH $i "/bin/cat /data/configs/EntityConfig/popDistance.csv_orig"|sed 's/-/_/g' > popDistance.csv
   scp popDistance.csv root@$i:/data/configs/EntityConfig/
   echo "Configuration Complete on Node $i "
done

}

function rubix_conf {

host=$1   
$SSH $host "$CLI < /var/home/root/rubix-config.cfg" 
$SSH $host "$CLI -t 'en' 'conf t' 'pm process rubix launch auto' 'wr me'"
$SSH $host "$CLI -t 'en' 'conf t' 'pm process rubix launch relaunch auto' 'wr me'"

}


function tps_fs {

host=$1
type=$2   ### type of node (datanode/rubix)

if [[ "$type" -eq 1 ]]
then
mount_point=/data/hadoop-admin
else
mount_point=/data/rubix
fi


fs=`$SSH $host "/opt/tms/bin/cli -t 'en' 'sh run full'" | grep "tps fs" | head -1  | awk '{print $3}'`

if [ ! -z $fs ]
then
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'no tps fs $fs enable' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'no tps fs $fs' 'wr mem'"
fi

$SSH $host "mount -o remount,rw /"
$SSH $host "/sbin/modprobe dm-multipath"
init_name=`$SSH $host "hostname"`
new_fs=`$SSH $host "hostname"|sed 's/-//g'`

wwid=`$SSH $host "/sbin/multipath -ll | head -1" | awk -F"(" '{print $2}' | awk -F")" '{print $1}'`
uuid=`$SSH $host "blkid  | grep -w mapper" | awk -F"=" '{print $3}' | awk '{print $1}' | sed 's/"//g'`

$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs $new_fs mount-point $mount_point' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs $new_fs mount-option mount-always' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs $new_fs wwid $wwid' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs $new_fs uuid $uuid' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs $new_fs enable' 'wr mem'"


}
######## RGE  ######## 


function preupgrade {

for i in $gdsvzbrge1
do
	echo "------ taking backup of setup properties -------"
        $SSH $i "mkdir -p /data/BackupFiles/"
	$SSH $i "cp /opt/tms/rge-bizreflex3.0_as701/WEB-INF/classes/setup.properties /data/BackupFiles/setup.properties_bkp"
	$SSH $i "cp /opt/samples/bizreflex-rubix-config/rubix/cli.properties /data/BackupFiles/cli.properties_bkp"
done	

scp -qr root@${gdsvzbrge1}:/data/BackupFiles/ root@${gdsvzbrge2}:/data/

}


function applypatch_rge {

clear
echo "------- INSTALLING PATCH ON ALL RGE NODES -----------"
for i in $gdsvzbrge1 $gdsvzbrge2 
do
    scp -q $PWD/patches/bizreflex3.4.rc2.p2.tgz root@${i}:/tmp
    scp -q $PWD/patches/bizreflex3.4.rc2.p3.tgz root@${i}:/tmp
    scp -q $PWD/patches/bizreflex3.4.rc2.p4.tgz root@${i}:/tmp
    scp -q $PWD/patches/bizreflex3.4.rc2.p5.tgz root@${i}:/tmp
    scp -q $PWD/patches/bizreflex3.4.rc2.vzb.180.days.support.p1.tgz root@${i}:/tmp
    scp -q $PWD/patches/bizreflex3.4.rc2.vzb.180.days.support.p2.tgz root@${i}:/tmp
    echo "Mounting ${i} in read-write mode"
    $SSH ${i} "mount -o remount,rw /"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.p2.tgz"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.p2" | grep -i success
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.p3.tgz"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.p3" | grep -i success
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.p4.tgz"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.p4" | grep -i success
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.p5.tgz"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.p5" | grep -i success
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.vzb.180.days.support.p1.tgz"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.vzb.180.days.support.p1" | grep -i success
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.vzb.180.days.support.p2.tgz"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.vzb.180.days.support.p2" | grep -i success
    echo "-------------- Done --------------------------"
    echo ""
done
}


function post_rge {

echo "--------- Configuring RGE nodes ----------"
for i in $gdsvzbrge1 $gdsvzbrge2
do
   $SSH $i "mount -o remount,rw /"
   scp $PWD/vzbrge_$i.tgz root@${i}:/
   $SSH $i "/opt/tps/bin/pmx.py register iscsi"
   tps_fs $i 2
   $SSH $i "$CLI -t 'en' 'conf t' 'pm process rubix terminate'"
   $SSH $i "cd / ; tar -xzf vzbrge_$i.tgz"
   $SSH $i "scp -q root@${gdsvzbrubvip}:/data/configs/EntityConfig/portIdName.csv /data/configs/EntityConfig/" 
   $SSH $i 'echo "MaxStartups 20" >> /var/opt/tms/output/sshd_config'
   $SSH $i "$CLI -t 'en' 'conf t' 'pm process sshd restart'"
   $SSH $i "$CLI  < /var/home/root/drbd.cfg"
   $SSH $i "$CLI  < /var/home/root/rge-config.cfg"
   $SSH $i "$CLI < /var/home/root/reportscluster.cfg"
   $SSH $i "$CLI -t 'en' 'conf t' 'pm process rubix launch auto' 'wr me'"
   $SSH $i "$CLI -t 'en' 'conf t' 'pm process rubix launch relaunch auto' 'wr me'" 
   $SSH $i "mkdir -p /data/rubix/rubix_report/"
   $SSH $i "touch /data/rubix/rubix_report/disk_mounted"
   $SSH $i "mkdir -p /data/configs/EntityConfig/"
   $SSH $i 'cd /opt/tms/bizreflex-bizreflex3.3/WEB-INF/classes;/usr/bin/python TreeCacheEntries.py --60m="1h:336;3h:496;1d:62" --1h="1h:23;3h:0;1d:0;7d:0;1M:0" --1d="1d:1;7d:0;1M:0" --1w="7d:1;1M:0" --1M="1M:1" --5m="5m:35712;1h:0;3h:0;1d:0;7d:0;1M:0"'
   $SSH $i "rm -rf /data/apache-tomcat/apache-tomcat-7.0.27_as701"
   $SSH $i "cd /data/apache-tomcat/ ; gzip -dc tomcat.tar.gz |tar xf -"
   $SSH $i "sed -i '/Access log processes/i\<!-- Remote IP Valve --> \n<Valve className=\"org.apache.catalina.valves.RemoteIpValve\" remoteIpHeader=\"x-forwarded-for\" remoteIpProxiesHeader=\"x-forwarded-by\" \/\>' /data/apache-tomcat/apache-tomcat-7.0.27/conf/server.xml" 
   $SSH $i "cp /data/BackupFiles/setup.properties_bkp /opt/tms/rge-bizreflex3.3/WEB-INF/classes/setup.properties"
   $SSH $i "cp /data/BackupFiles/cli.properties_bkp /opt/samples/ip-solutions-config/rubix/cli.properties"
done
   $SSH $gdsvzbrge1 "cp /data/Backup_Pre_Upgrade/apache-tomcat-7.0.27_as701/vzb_cert.pem /data/"
   $SSH $gdsvzbrge1 "scp -q /data/Backup_Pre_Upgrade/apache-tomcat-7.0.27_as701/vzb_cert.pem root@${gdsvzbrge2}:/data/"
   $SSH $gdsvzbrge1 "/opt/tms/bin/cli -t 'en' 'conf t' 'httpd add-cert-file /data/vzb_cert.pem' 'pm process httpd restart' 'wr mem'"
   $SSH $gdsvzbrge2 "/opt/tms/bin/cli -t 'en' 'conf t' 'httpd add-cert-file /data/vzb_cert.pem' 'pm process httpd restart' 'wr mem'"

} 

function RSYNC { 

$SSH $gdsvzbrge1 'echo "*/5 * * * * /opt/etc/scripts/rge_rsync/rge_sync.sh 108.55.163.31" | crontab - '
$SSH $gdsvzbrge2 'echo "*/5 * * * * /opt/etc/scripts/rge_rsync/rge_sync.sh 108.55.163.70" | crontab - '

$SSH $gdsvzbrge1 "chmod +x /opt/samples/ip-solutions-config/logdownloader/createSymlink.sh ; /opt/samples/ip-solutions-config/logdownloader/createSymlink.sh /data/instances/br_rge/0/sla_logs /opt/tms/lib/web/content/"
$SSH $gdsvzbrge2 "chmod +x /opt/samples/ip-solutions-config/logdownloader/createSymlink.sh ; /opt/samples/ip-solutions-config/logdownloader/createSymlink.sh /data/instances/br_rge/0/sla_logs /opt/tms/lib/web/content/"
}

function NN_bakup {

for i in $gdsvzbcol1 $gdsvzbcol2
do
        echo "------ taking backup logdownloader xml files -------"
        $SSH $i "mkdir -p /data/BackupFiles/"
        $SSH $i "cp /opt/samples/bizreflex-rubix-config/logdownloader/tcp.xml /data/BackupFiles/tcp.xml_bkp"
        $SSH $i "cp /opt/samples/bizreflex-rubix-config/logdownloader/config.xml /data/BackupFiles/config.xml_bkp"
    	$SSH $i "cp /opt/catalogue/bizreflex/as.map /data/BackupFiles/as.map_bkp"
done

}

function stopRE {

	id=`$SSH $gdsvzbcolvip "ps -ef|grep -i 'bin/re'"|grep -v grep|awk '{print $2}'`
	$SSH $gdsvzbcolvip "kill -9 $id"

}

function validation_DN {

for i in $gdsvzbcmp1 $gdsvzbcmp2 $gdsvzbcmp3 $gdsvzbcmp4 $gdsvzbcmp5 $gdsvzbcmp6 $gdsvzbcmp7 $gdsvzbcmp8 $gdsvzbcmp9 $gdsvzbcmp10 $gdsvzbcmp11 $gdsvzbcmp12 $gdsvzbcmp13
do
	echo "------ validaing $i datanodes  -------"
	$SSH $i "/bin/mount |grep 'hadoop-admin'"
	if [ $? -ne 0 ]
	then
		echo "PROBLEM in mounting the node"
	fi
	$SSH $i "ps -ef|grep -i datanode|grep -v grep"|awk '{ print $9 }'
	if [ $? -ne 0 ]
        then
                echo "PROBLEM no datanode found"
        fi
	$SSH $i "ps -ef|grep -i tasktrack|grep -v grep"
        if [ $? -ne 0 ]
        then
                echo "PROBLEM no tasktrack found"
        fi

	$SSH $i "hadoop dfsadmin -report"|head -12
	read -p "Continue (y): "
	[ "$REPLY" != "y" ] && exit 0 
done	
}

function col_settings {

host=$1
echo " "
echo -n "Configuration of Collector on $host -----"
id=`$SSH $host "/opt/tms/bin/cli -t 'en' 'show run full'|grep collector|grep instance|head -1"|awk '{print $NF}'`
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'collector modify-instance $id modify-adaptor netflow file-format binCompactCompression' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'pm process collector restart'"
$SSH $host "mount -o remount,rw /"
echo " Done"
echo "Kernel Parameter Configuration on $host -----"
$SSH $host "sed -i 's/net.ipv4.ip_forward\ =\ 1/net.ipv4.ip_forward\ =\ 0/g' /etc/sysctl.conf"
$SSH $host "sed -i 's/net.ipv4.conf.default.rp_filter\ =\ 1/net.ipv4.conf.default.rp_filter\ =\ 0/g' /etc/sysctl.conf"
$SSH $host "sed -i 's/net.ipv4.conf.all.rp_filter\ =\ 1/net.ipv4.conf.all.rp_filter\ =\ 0/g' /etc/sysctl.conf"
$SSH $host "/sbin/sysctl -p 2> /dev/null"
}

function validation_NN {

for i in $gdsvzbcol1 $gdsvzbcol2
do
	echo "------ validaing $i NameNode  -------"
	$SSH $i "drbd-overview"

        read -p "Continue (y): "
        [ "$REPLY" != "y" ] && exit 0

	$SSH $i "ps -ef|grep -i namenode"

        read -p "Continue (y): "
        [ "$REPLY" != "y" ] && exit 0	
done	

}
 

function samplicator {

host=$1
scp -q root@${gdsvzbcolvip}:/data/configs/samplicate.cfg root@${host}:/data/configs/samplicate.cfg
echo " "
echo -n "Configuration of Samplicator on $host -----"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process samplicate launch enable' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process samplicate launch auto' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process samplicate launch relaunch auto' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process samplicate path /opt/tms/bin/samplicate' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process samplicate launch params 1 -S' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process samplicate launch params 2 -p' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process samplicate launch params 3 2055' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process samplicate launch params 4 -b' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process samplicate launch params 5 134217728' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process samplicate launch params 6 -c' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process samplicate launch params 7 /data/configs/samplicate.cfg' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process samplicate restart' 'wr mem'"
echo " Done"

}


function logdownloader {

host=$1
echo -n "Configuration of Logdownloader on $host -----"
$SSH $host "mkdir -p /data/configs/logdownloader/"
$SSH $host "cp /data/BackupFiles/tcp.xml_bkp /data/configs/logdownloader/tcp.xml"
$SSH $host "cp /data/BackupFiles/config.xml_bkp /data/configs/logdownloader/config.xml"
$SSH $host "mount -o remount,rw /"
start=`$SSH $host "cat /data/configs/logdownloader/config.xml"|grep -n -B 4 reportStats |grep -w "<Djob>"|cut -d'-' -f1`
stop=`$SSH $host "cat /data/configs/logdownloader/config.xml"|grep -n -A 30 reportStats|grep -w "</Djob>"|cut -d'-' -f1`
$SSH $host "sed -i -e '${start},${stop}d' /data/configs/logdownloader/config.xml"
$SSH $host "cp /data/BackupFiles/as.map_bkp /opt/catalogue/bizreflex/as.map"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process log_downloader launch auto' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process log_downloader launch environment set CLASSPATH /opt/tms/java/classes:/opt/hadoop/conf:/opt/hadoop/hadoop-core-0.20.203.0.jar:/opt/hadoop/lib/commons-configuration-1.6.jar:/opt/hadoop/lib/commons-logging-1.1.1.jar:/opt/hadoop/lib/commons-lang-2.4.jar:/opt/tms/java/MemSerializer.jar' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process log_downloader launch environment set LD_LIBRARY_PATH /opt/hadoop/c++/Linux-amd64-64/lib:/usr/java/jre1.6.0_25/lib/amd64/server:/opt/tps/lib' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process log_downloader launch environment set LD_PRELOAD libjemalloc.so' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process log_downloader path /bin/bash' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process log_downloader launch params 1 /opt/samples/ip-solutions-config/logdownloader/logDownloader.sh' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process log_downloader launch params 2 /data/configs/logdownloader/tcp.xml' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process log_downloader launch params 3 /data/configs/logdownloader/config.xml' 'wr mem'"	


#### changes for djob pending..	
echo " Done"

}


function xml_changes {

host=$1
$SSH $host "sed -i '/\/configuration>/i<property>\n    <name>mapred.task.timeout</name>\n    <value>3600000</value>\n    <description></description>\n</property>' /opt/samples/hadoop_conf/mapred-site.xml.template"
$SSH $host "sed -i '/\/configuration>/i<property>\n    <name>mapred.task.timeout</name>\n    <value>3600000</value>\n    <description></description>\n</property>' /opt/hadoop/conf/mapred-site.xml"

}


function bgp_Quagga {

build=`$SSH $host "/opt/tms/bin/cli -t 'en' 'sh version'" | grep "Build ID" | awk '{print $NF}'`
if [ $build == "bizreflex3.2.rc3" ]
then
$SSH $gdsvzbcol1 'cd /data/routing/bgp/tables/ ; for i in `ls -1rt | tail -5`; do y=`echo $i | cut -d"." -f2`; d=`date -d@$y "+%Y%m%d.%H%M"`; mv $i bview.$d; done'
else
$SSH $gdsvzbcol1 "sed -i -e 's/updates.%Y%m%d.%H%M/updates.%s/' -i -e 's/bview.%Y%m%d.%H%M/bview.%s/' /data/configs/zebra/bgpd.conf"
$SSH $gdsvzbcol2 "mkdir -p /data/configs/zebra/" 2> /dev/null
$SSH $gdsvzbcol2 "mkdir -p /data/routing/bgp/log/" 2> /dev/null
$SSH $gdsvzbcol2 "mkdir -p /data/routing/bgp/tables/" 2> /dev/null
$SSH $gdsvzbcol2 "mkdir -p /data/routing/bgp/updates/" 2> /dev/null
$SSH $gdsvzbcol1 "scp -q /data/configs/zebra/* root@${gdsvzbcol2}:/data/configs/zebra/"
$SSH $gdsvzbcol1 'cd /data/routing/bgp/tables/ ; for i in `ls -1rt  | tail -5 `; do y=`echo $i | cut -d"." -f2`; h=`echo $i | cut -d"." -f3`; d=`date --date="$y $h" +%s`; mv $i bview.$d; done'
echo "Copying Bview dumps on $gdsvzbcol2.."
$SSH $gdsvzbcol1 "scp -qr /data/routing/bgp/tables/ root@${gdsvzbcol2}:/data/routing/bgp/"
$SSH $gdsvzbcol1 "scp -qr /data/routing/bgp/updates/ root@${gdsvzbcol2}:/data/routing/bgp/"
$SSH $gdsvzbcol1 "/usr/bin/bgpd -d -u root -g root -n -f /data/configs/zebra/bgpd.conf"
$SSH $gdsvzbcol2 "/usr/bin/bgpd -d -u root -g root -n -f /data/configs/zebra/bgpd.conf"
fi
}


function RE_process {


host=$1

$SSH $host " [ -d /data/configs/re_configs/ ] || mkdir /data/configs/re_configs/"
$SSH $host "cp /data/configs/re_configs/re_config_updated.xml /data/configs/re_configs/re_config_updated_bkp.xml"
scp -q $PWD/re_config.xml root@$gdsvzbcol1:/data/configs/re_configs/re_config_updated.xml
scp -q $PWD/re_config.xml root@$gdsvzbcol2:/data/configs/re_configs/re_config_updated.xml

re_start_time=`date "+%FT%H:%M"`

$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'sm service create INSTA::BLOCKING:1' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'sm service modify INSTA::BLOCKING:1 service-info insta-server-info1' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'sm service-info create insta-server-info1' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'sm service-info modify insta-server-info1 host $gdsvzbinsnewvip' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'sm service-info modify insta-server-info1 port 11111' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'sm service-info modify insta-server-info1 service-type TCP_SOCKET' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process re launch auto' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process re launch environment set CLASSPATH /opt/tms/java/classes:/opt/hadoop/conf:/opt/hadoop/hadoop-core-0.20.203.0.jar:/opt/hadoop/lib/commons-configuration-1.6.jar:/opt/hadoop/lib/commons-logging-1.1.1.jar:/opt/hadoop/lib/commons-lang-2.4.jar:/opt/tms/java/MemSerializer.jar' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process re launch environment set LD_LIBRARY_PATH /opt/hadoop/c++/Linux-amd64-64/lib:/usr/java/jre1.6.0_25/lib/amd64/server:/opt/tps/lib' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process re launch environment set LD_PRELOAD libjemalloc.so' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process re launch params 1 -p' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process re launch params 2 $re_start_time' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process re launch params 3 -f' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process re launch params 4 /data/configs/re_configs/re_config_updated.xml' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process re terminate ' 'wr mem'"
$SSH $host "$CLI -t 'en' 'conf t' 'pm process re terminate'"
$SSH $host "service pm restart"
$SSH $host "$CLI -t 'en' 'conf t' 'pm process re terminate'"
echo -n "Configuration of RE on $host -----"
sleep 3
echo " Done"

}

function validate_col_samp_logd_quagga {

for i in $gdsvzbcol1 $gdsvzbcol2
do

	echo "--------- validation on $i ------------"
	echo "validating logdownloader"
	$SSH $i "/opt/tms/bin/cli -t 'en' 'show pm process log_downloader'"
	read -p "Continue (y): "
	[ "$REPLY" != "y" ] && exit 0
	echo "validating Quagga process"
	$SSH $i "ps -ef|grep -i bgpd"
	read -p "Continue (y): "
        [ "$REPLY" != "y" ] && exit 0
	echo "validating Collector and samplicator process"
	$SSH $i "/opt/tms/bin/cli -t 'en' 'show pm process collector'"
        read -p "Continue (y): "
        [ "$REPLY" != "y" ] && exit 0
	$SSH $i "/opt/tms/bin/cli -t 'en' 'show pm process samplicate'"
        read -p "Continue (y): "
        [ "$REPLY" != "y" ] && exit 0

done

}

function rem_old_jobs {

for i in $gdsvzbcol1 $gdsvzbcol2
do
	$SSH $i "$PMX 'subshell oozie remove job all' " 
	$SSH $i "$PMX 'subshell oozie remove dataset all' "
	$SSH $i "$CLI -t 'en' 'conf t' 'wr me'"
done
}

function cp_job_config {

for i in $gdsvzbcol1 $gdsvzbcol2
do
	scp -q $PWD/job_config.tgz root@${i}:/
	$SSH ${i} "cd / ; tar -xzf job_config.tgz"
done

}

function rem_old_gleaning {

$SSH $gdsvzbcolvip "$HADOOP dfs -mv /data/_BizreflexCubes/Gleaning /data/_BizreflexCubes/Gleaning_bkp"
$SSH $gdsvzbcolvip "$HADOOP dfs -mv /data/BR_OUT/oozie/PrefixJob/ /data/BR_OUT/oozie/PrefixJob_bkp"

}

function copy_files {

share_sshkey_TM $gdsvzbrubvip $gdsvzbcolvip
$SSH $gdsvzbcolvip "$HADOOP dfs -mv /data/routing/aib /data/routing/aib_bkp"
scp -q root@$gdsvzbrubvip:/data/configs/EntityConfig/portDefinition.csv  root@$gdsvzbcolvip:/data/aib_new
$SSH $gdsvzbcolvip "$HADOOP dfs -put /data/aib_new /data/routing/aib"
scp -q root@$gdsvzbrubvip:/data/configs/EntityConfig/popDefinition.csv root@$gdsvzbcolvip:/data/
$SSH $gdsvzbcolvip "$HADOOP dfs -put /data/popDefinition.csv /data/routing/popDefinition.csv"
scp -q root@$gdsvzbrubvip:/data/configs/EntityConfig/popDistance.csv root@$gdsvzbcolvip:/data/
$SSH $gdsvzbcolvip "$HADOOP dfs -put /data/popDistance.csv /data/routing/popDistance.csv"
$SSH $gdsvzbcolvip "$HADOOP dfs -mkdir /data/_BizreflexCubes/RouterNameToID_upgrade"
$SSH $gdsvzbcolvip "$HADOOP dfs -cp /data/_BizreflexCubes/RouterNameToID/routertoidmap /data/_BizreflexCubes/RouterNameToID_upgrade/routertoidmap"
}


function bizrules_config {

for i in $gdsvzbcol1 $gdsvzbcol2
do
$SSH $i "cp /data/configs/jobs/config_bizrules.xml /data/configs/jobs/config_bizrules_upgrade.xml"
$SSH $i "$HADOOP "
done
}

function stringidmaps_bkp {

i=$gdsvzbinsvip
#db=`$SSH ${gdsvzbinsvip} "$CLI -t 'en' 'sh run full' | grep cubes-database" | awk '{print $NF}'`
#dbname=`echo $db"_stringidmap"`
$SSH $i '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=br_vzbr_27feb_stringidmap -e "select * from  router_idmap " > /tmp/old_rtridmap.txt; sed -i 1d /tmp/old_rtridmap.txt; sed -i "s/\t/\|/g" /tmp/old_rtridmap.txt'
$SSH $i '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=br_vzbr_27feb_stringidmap -e "select * from  pop_idmap " > /tmp/old_pop_idmap.txt; sed -i 1d /tmp/old_pop_idmap.txt; sed -i "s/\t/\|/g" /tmp/old_pop_idmap.txt'
$SSH $i '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=br_vzbr_27feb_stringidmap -e "select * from  as_idmap " > /tmp/old_as_idmap.txt; sed -i 1d /tmp/old_as_idmap.txt; sed -i "s/\t/\|/g" /tmp/old_as_idmap.txt'
$SSH $i '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=br_vzbr_27feb_stringidmap -e "select * from  customer_idmap " > /tmp/old_customer_idmap.txt; sed -i 1d /tmp/old_customer_idmap.txt; sed -i "s/\t/\|/g" /tmp/old_customer_idmap.txt'
$SSH $i '/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=br_vzbr_27feb_stringidmap -e "select * from  generic_idmap " > /tmp/old_generic_idmap.txt; sed -i 1d /tmp/old_generic_idmap.txt; sed -i "s/\t/\|/g" /tmp/old_generic_idmap.txt'

$SSH $i '/bin/mv /tmp/old*.txt /data/BackupFiles/'
$SSH ${gdsvzbinsnew1} "mkdir -p /data/BackupFiles/"
$SSH ${gdsvzbinsnew2} "mkdir -p /data/BackupFiles/"
$SSH $i "scp -q /data/BackupFiles/old*_idmap.txt admin@${gdsvzbinsnew1}:/data/BackupFiles/"
$SSH $i "scp -q /data/BackupFiles/old*_idmap.txt admin@${gdsvzbinsnew2}:/data/BackupFiles/"


}


function InstaConfig {

wwid1=`$SSH $gdsvzbinsvip "/sbin/multipath -ll | grep dbroot1" | awk -F"(" '{print $2}' | awk -F")" '{print $1}'`
wwid2=`$SSH $gdsvzbinsvip "/sbin/multipath -ll | grep dbroot2" | awk -F"(" '{print $2}' | awk -F")" '{print $1}'`
wwid3=`$SSH $gdsvzbinsvip "/sbin/multipath -ll | grep dbroot3" | awk -F"(" '{print $2}' | awk -F")" '{print $1}'`
wwid4=`$SSH $gdsvzbinsvip "/sbin/multipath -ll | grep dbroot4" | awk -F"(" '{print $2}' | awk -F")" '{print $1}'`
for i in $gdsvzbins1 $gdsvzbins2
do
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'mpio multipaths alias dbroot1 wwid $wwid1' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'mpio multipaths alias dbroot2 wwid $wwid2' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'mpio multipaths alias dbroot3 wwid $wwid3' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'mpio multipaths alias dbroot4 wwid $wwid4' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta instance 0 cubes-xml /opt/tms/xml_schema/BizreflexCubeDefinition.xml' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta instance 0 service-port 11111' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta instance 0 dataRetentionPeriod 180' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta instance 0 cubes-database vzb_br34' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process insta launch environment set LD_LIBRARY_PATH /opt/hadoop/c++/Linux-amd64-64/lib:/usr/java/jre1.6.0_25/lib/amd64/server:/opt/tps/lib:/platform_latest/insta/lib' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process insta launch environment set CLASSPATH /opt/tms/java/classes:/opt/hadoop/conf:/opt/hadoop/hadoop-core-0.20.203.0.jar:/opt/hadoop/lib/commons-configuration-1.6.jar:/opt/hadoop/lib/commons-logging-1.1.1.jar:/opt/hadoop/lib/commons-lang-2.4.jar' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process insta launch auto' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process insta launch relaunch auto' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process insta launch enable' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb set install-mode multi-server-install' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb set module-install-type combined' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb username root' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb password \"\"' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb cluster-name VZBINSTAHA' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb set storage-type ext2' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb dbroot 1' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb dbroot 1 storage-location /dev/mapper/dbroot1' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb dbroot 2' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb dbroot 2 storage-location /dev/mapper/dbroot2' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb dbroot 3' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb dbroot 3 storage-location /dev/mapper/dbroot3' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb dbroot 4' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb dbroot 4 storage-location /dev/mapper/dbroot4' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb modulecount 2' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb ipaddr $i' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb hamgr $gdsvzbinsvip' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb module 1' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb module 2' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb module 1 ip $gdsvzbins1' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb module 2 ip $gdsvzbins2' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta ipc serviceport 55555' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'internal set modify - /nr/insta/connection_pool_size value uint16 40' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'internal set modify - /nr/insta/instance/0/max_outstanding_query  value uint16 24' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'internal set modify - /nr/insta/common/infinidb/config/querypoolsize value uint16 8' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'internal set modify - /nr/insta/instance/0/read_temptablethreshold value uint32 500' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'internal set modify - /nr/insta/instance/0/max_query_interval value uint32 2678400' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process insta restart'"

done
echo "Insta Configuration Done ... "
$SSH $gdsvzbinsvip 'cat /var/log/messages | grep "Waiting for Infinidb setup" | tail -3'

}
function insta_db_bkp {

echo "taking full db backup"
read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0
echo "enter DB NAME"
read DB_NAME
echo "start time"
read start_time
echo "end time"
read end_time
echo "Directory to take backup"
read dir

$SSH $gdsvzbinsvip "/usr/bin/python /usr/local/bin/idbmgmt.py -o backup -d DB_NAME -s $start_time -e $end_time -b $dir"

}

function uninstall_inifnidb {

$SSH $gdsvzbinsvip "/opt/tms/bin/cli -t 'en' 'conf t' 'insta infinidb uninstall'"
while true
do
  clear
  echo "-------- checking inifnidb status ---------"

  $SSH $gdsvzbinsvip "/opt/tms/bin/cli -t 'en' 'conf t' 'insta infinidb get-status-info'"  
  echo
  echo " THIS SCREEN WILL AUTO REFRESH EVERY 30s"
  echo "Hit CTRL+C to break, Once infinidb is uninstalled"
  sleep 30
done

}


function insta_patch {


clear
echo "------- INSTALLING PATCH ON ALL INSTA NODES -----------"
for i in $gdsvzbinsnew1 $gdsvzbinsnew2
do
    scp -q $PWD/patches/bizreflex3.4.rc2.p2.tgz root@${i}:/tmp
    scp -q $PWD/patches/bizreflex3.4.rc2.p3.tgz root@${i}:/tmp

    echo "Mounting ${i} in read-write mode"
    $SSH ${i} "mount -o remount,rw /"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.p2.tgz"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.p2" | grep -i success
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch fetch /tmp/bizreflex3.4.rc2.p3.tgz"
    $SSH ${i} "/opt/tps/bin/pmx.py subshell patch install bizreflex3.4.rc2.p3" | grep -i success
    echo ""
done
for i in $gdsvzbinsnew1 $gdsvzbinsnew2
do
	$SSH ${i} "rm -rf /opt/calpont-*.tar.gz"
	$SSH ${i} "rm -rf /root/calpont-*.tar.gz"
	scp -q $PWD/patches/calpont-infinidb-ent-3.8.0-5.x86_64.bin.tar.gz root@${i}:/opt/
done

}

function post_patch_insta {


for i in $gdsvzbins1 $gdsvzbins2
do
	id=`$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'show run full'"|grep "insta instance"|head -1|awk '{print $3}'`
	$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process insta restart'"
	$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta instance $id cube-schema-upgrade summary' 'wr mem'"
	$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta instance $id cube-schema-upgrade apply' 'wr mem'"
done

echo "checking infinidb is up and running or not."

read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0

for i in $gdsvzbins1 $gdsvzbins2
do
        echo "validating $i insta node"
	$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta infinidb get-status-info'"
	read -p "Continue (y): "
        [ "$REPLY" != "y" ] && exit 0
done

}

function config_pgsql {

for i in $gdsvzbinsnew1 $gdsvzbinsnew2
do
echo "Installing Postgres DB on node $i ... "
$SSH $i "/opt/tps/bin/pmx.py register pgsql"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'tps pgsql dbroot /data/pgsql' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'tps pgsql mode external' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process tps restart'"
sleep 40
echo "Check PGSQL Status"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'show tps pgsql status'"
done
}

function create_db {

i=$gdsvzbinsnewvip
$SSH $i 2> /dev/null << EOF
psql -U postgres
create database rgedb;
create database rubixdb;
EOF

}

function run_RE {

$SSH $gdsvzbcolvip "$HADOOP dfs -mv /data/routing/merged_asib /data/routing/merged_asib_bkp"
$SSH $gdsvzbcolvip "$HADOOP dfs -rmr /tmp/b7" 2> /dev/null
$SSH $gdsvzbcolvip "$HADOOP dfs -rmr /tmp/b6" 2> /dev/null
echo -n "Starting RE on both NameNodes ..."
time=`$SSH $gdsvzbcolvip "ls -lrt /data/routing/bgp/tables/" | grep -v total | tail -5 | head -1 | awk '{print $9}' | awk -F"." '{print $2}'`
re_start_time=`date -d@$time "+%FT%H:%M"`
for i in $gdsvzbcol1 $gdsvzbcol2
do
	$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process re launch params 2 $re_start_time' 'wr mem'"
	$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process re restart'"

done
echo "Done"

}

function start_rge {

for i in $gdsvzbrge1 $gdsvzbrge2
do
echo -n "Starting Rubix on node $i ..."
$SSH $i "touch /data/rubix/rubix_report/disk_mounted"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process rubix restart'"
echo "Done"
done

}

function start_rubix {

for i in $gdsvzbrub1 $gdsvzbrub2 $gdsvzbrub3 $gdsvzbrub4 $gdsvzbrub5 $gdsvzbrub6
do
echo -n "Starting Rubix on node $i ..."
$SSH $i "touch /data/rubix/vzbrubix/disk_mounted"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process rubix restart'"
echo "Done"
done

}

function start_jobs {

jobs="master_job,bizrules_job,aggregate_1d,export_agg_1d,aggregate_1w,export_agg_1w,aggregate_1m,export_agg_1m,unrolledAsJob,PotAsJob,ExecWhiteListJob,sla1,sla2,oozie_sla,sessionLogsJob"

for i in `echo $jobs|sed 's/,/\n/g'`
do
	$SSH $gdsvzbcolvip "/opt/tps/bin/pmx.py subshell oozie run job $i"
	$SSH $gdsvzbcolvip "/opt/tms/bin/cli -t 'en' 'conf t' 'wr mem'"
done


$SSH $gdsvzbcolvip "/opt/tps/bin/pmx.py subshell oozie run job export_job"

$SSH $gdsvzbcolvip "/opt/tms/bin/cli -t 'en' 'conf t' 'wr mem'"

}

function restart_rubix_rge {


for i in $gdsvzbrub1 $gdsvzbrub2 $gdsvzbrub3 $gdsvzbrub4 $gdsvzbrub5 $gdsvzbrub6 $gdsvzbrge1 $gdsvzbrge2
do
        $SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process rubix terminate'"
        $SSH $i "'/opt/tms/bin/cli -t 'en' 'conf t' 'pm process rubix restart'"
done
}

function populate_string_idmaps {

$SSH $gdsvzbinsnewvip 2> /dev/null << EOF
/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=vzbr_34 -e "load data infile '/data/BackupFiles/old_pop_idmap.txt' into table stringid_pop_idmap fields terminated by '|' "
/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=vzbr_34 -e "load data infile '/data/BackupFiles/old_rtridmap.txt' into table stringid_router_idmap fields terminated by '|' "
/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=vzbr_34 -e "load data infile '/data/BackupFiles/old_as_idmap.txt' into table stringid_as_idmap fields terminated by '|' "
/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=vzbr_34 -e "load data infile '/data/BackupFiles/old_customer_idmap.txt' into table stringid_customer_idmap fields terminated by '|' "
/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root --database=vzbr_34 -e "load data infile '/data/BackupFiles/old_generic_idmap.txt' into table stringid_generic_idmap fields terminated by '|' "
EOF

}

function Migrate_Innodb {

i=$gdsvzbinsnewvip
$SSH $i "awk -F, '{print \$0 \",\\\N\" \",\\\N\"}' /data/BackupFiles/old_user_data.txt > /data/BackupFiles/old_user_data_new.txt"
$SSH $i "mv  /data/BackupFiles/old_user_data.txt /data/BackupFiles/old_user_data_bkp.txt"
$SSH $i "mv /data/BackupFiles/old_user_data_new.txt /data/BackupFiles/old_user_data.txt"

$SSH $i "psql -U postgres -d rubixdb -c \"\copy asblacklistrule_bizreflex_vzb_unknown_cluster from /data/BackupFiles/old_asblack_data.txt with DELIMITER ',' \" "
$SSH $i "psql -U postgres -d rubixdb -c \"\copy asprospectrule_bizreflex_vzb_unknown_cluster from '/data/BackupFiles/old_asprspct_data.txt' with DELIMITER ',' \" "
$SSH $i "psql -U postgres -d rubixdb -c \"\copy entitynametoasprirule_bizreflex_vzb_unknown_cluster from '/data/BackupFiles/old_entity_data.txt' with DELIMITER ',' \" "
$SSH $i "psql -U postgres -d rubixdb -c \"truncate table idnamemap_bizreflex_vzb_unknown_cluster \" "
$SSH $i "psql -U postgres -d rubixdb -c \"\copy idnamemap_bizreflex_vzb_unknown_cluster from '/data/BackupFiles/old_idnamemap_data.txt' with DELIMITER ',' \" "
$SSH $i "psql -U postgres -d rubixdb -c \"truncate table userinfo cascade \" "
$SSH $i "psql -U postgres -d rubixdb -c \"truncate table role cascade \" "
$SSH $i "psql -U postgres -d rubixdb -c \"truncate table groupinfo cascade \" "
$SSH $i "psql -U postgres -d rubixdb -c \"truncate table modulepermissiondata cascade \" "
$SSH $i "psql -U postgres -d rubixdb -c \"truncate table role_modules \" "
$SSH $i "psql -U postgres -d rubixdb -c \"truncate table user_role \" "
$SSH $i "psql -U postgres -d rubixdb -c \"truncate table user_group \" "
$SSH $i "psql -U postgres -d rubixdb -c \"truncate table group_role \" "
$SSH $i "psql -U postgres -d rubixdb -c \"\copy userinfo from '/data/BackupFiles/old_user_data.txt' with DELIMITER ',' \" "
$SSH $i "psql -U postgres -d rubixdb -c \"\copy role from '/data/BackupFiles/old_role_data.txt' with DELIMITER ',' \" "
$SSH $i "psql -U postgres -d rubixdb -c \"\copy groupinfo from '/data/BackupFiles/old_grpinfo_data.txt' with DELIMITER ',' \" "
$SSH $i "psql -U postgres -d rubixdb -c \"\copy modulepermissiondata from '/data/BackupFiles/old_module_data.txt' with DELIMITER ',' \" "
$SSH $i "psql -U postgres -d rubixdb -c \"\copy role_modules from '/data/BackupFiles/old_rolemodule_data.txt' with DELIMITER ',' \" "
$SSH $i "psql -U postgres -d rubixdb -c \"\copy user_role from '/data/BackupFiles/old_user_role_data.txt' with DELIMITER ',' \" "
$SSH $i "psql -U postgres -d rubixdb -c \"\copy user_group from '/data/BackupFiles/old_user_grp_data.txt' with DELIMITER ',' \" "
$SSH $i "psql -U postgres -d rubixdb -c \"\copy filter_bizreflex_vzb_unknown_cluster from '/data/BackupFiles/old_filter_data.txt' with DELIMITER ',' \" "
$SSH $i "psql -U postgres -d rubixdb -c \"\copy group_role from '/data/BackupFiles/old_grp_role_data.txt' with DELIMITER ',' \" "
$SSH $i "psql -U postgres -d rubixdb -c \"insert into role_modules values ('1','Summary') \" "

$SSH $i "psql -U postgres -d rubixdb -c \"CREATE TEMPORARY TABLE TMP_TABLE_123 ON COMMIT DROP AS SELECT SETVAL('entitynametoasprirule_bizreflex_vzb_unknown_cluster_id_seq', (SELECT MAX(id) FROM entitynametoasprirule_bizreflex_vzb_unknown_cluster) + 1) \" "
$SSH $i "psql -U postgres -d rubixdb -c \"CREATE TEMPORARY TABLE TMP_TABLE_123 ON COMMIT DROP AS SELECT SETVAL('filter_bizreflex_vzb_unknown_cluster_id_seq', (SELECT MAX(id) FROM filter_bizreflex_vzb_unknown_cluster) + 1) \" "
$SSH $i "psql -U postgres -d rubixdb -c \"CREATE TEMPORARY TABLE TMP_TABLE_123 ON COMMIT DROP AS SELECT SETVAL('asblacklistrule_bizreflex_vzb_unknown_cluster_id_seq', (SELECT MAX(id) FROM asblacklistrule_bizreflex_vzb_unknown_cluster) + 1) \" "
$SSH $i "psql -U postgres -d rubixdb -c \"CREATE TEMPORARY TABLE TMP_TABLE_123 ON COMMIT DROP AS SELECT SETVAL('asprospectrule_bizreflex_vzb_unknown_cluster_id_seq', (SELECT MAX(id) FROM asprospectrule_bizreflex_vzb_unknown_cluster) + 1) \" "
$SSH $i "psql -U postgres -d rubixdb -c \"CREATE TEMPORARY TABLE TMP_TABLE_123 ON COMMIT DROP AS SELECT SETVAL('revision_history_id_seq', (SELECT MAX(id) FROM revision_history) + 1) \" "
$SSH $i "psql -U postgres -d rubixdb -c \"CREATE TEMPORARY TABLE TMP_TABLE_123 ON COMMIT DROP AS SELECT SETVAL('userhistory_id_seq', (SELECT MAX(id) FROM userhistory) + 1) \" "
$SSH $i "psql -U postgres -d rubixdb -c \"CREATE TEMPORARY TABLE TMP_TABLE_123 ON COMMIT DROP AS SELECT SETVAL('role_id_seq', (SELECT MAX(id) FROM role) + 1) \" "
$SSH $i "psql -U postgres -d rubixdb -c \"insert into UserInfo (email, enabled, password, version, userName,timeZone) values ('configure@dummydomain.com', true, '19223a7bbd7325516f069df18b50', 0, 'sysadmin','EST');\" "
$SSH $i "psql -U postgres -d rubixdb -c \" insert into Role (id,roleName,version) values ((select MAX(id)+1 from Role),'sysadmin',0);\" "
$SSH $i "psql -U postgres -d rubixdb -c \" CREATE TEMPORARY TABLE TMP_TABLE_123 ON COMMIT DROP AS SELECT SETVAL('role_id_seq', (SELECT MAX(id) FROM role) + 1);\" "
$SSH $i "psql -U postgres -d rubixdb -c \" insert into user_role (userName, roleId)  select username as userName, id as roleId from userinfo, role where rolename='sysadmin' and username='sysadmin';\" "
$SSH $i "psql -U postgres -d rubixdb -c \" insert into MODULEPERMISSIONDATA (ROLEID) select  id from role where rolename='sysadmin';\" "
$SSH $i "psql -U postgres -d rubixdb -c \" insert into ROLE_MODULES (ROLE_ID, MODULES) select  id, 'Configure' from role where rolename='sysadmin';\" "

}

function insta_config {

for i in $gdsvzbinsnew1 $gdsvzbinsnew2
do
echo -n "Pushing Insta Config on node $i... "
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta instance-id create 0' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta instance 0 cubes-xml /opt/tms/xml_schema/BizreflexCubeDefinition.xml' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta instance 0 cubes-database vzbr_34' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta instance 0 service-port 11111' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta instance 0 dataRetentionPeriod 180' 'wr mem'" 
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process insta launch environment set LD_LIBRARY_PATH /opt/hadoop/c++/Linux-amd64-64/lib:/usr/java/jre1.6.0_25/lib/amd64/server:/opt/tps/lib:/platform_latest/insta/lib' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process insta launch environment set CLASSPATH /opt/tms/java/classes:/opt/hadoop/conf:/opt/hadoop/hadoop-core-0.20.203.0.jar:/opt/hadoop/lib/commons-configuration-1.6.jar:/opt/hadoop/lib/commons-logging-1.1.1.jar:/opt/hadoop/lib/commons-lang-2.4.jar' 'wr mem'" 
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process insta launch auto' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process insta launch relaunch auto' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process insta launch enable' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb set install-mode multi-server-install' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb set module-install-type combined' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb username root' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb password \"\"' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb cluster-name BRINSTAHA' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb set storage-type ext2' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb dbroot 1' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb dbroot 1 storage-location /dev/mapper/dbroot1' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb dbroot 2' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb dbroot 2 storage-location /dev/mapper/dbroot2' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb dbroot 3' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb dbroot 3 storage-location /dev/mapper/dbroot3' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb dbroot 4' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb dbroot 4 storage-location /dev/mapper/dbroot4' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb modulecount 2' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb ipaddr $i' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb hamgr $gdsvzbinsnewvip' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb module 1' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb module 2' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb module 1 ip $gdsvzbinsnew1' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta adapters infinidb module 2 ip $gdsvzbinsnew2' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'insta ipc serviceport 55555' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'internal set modify - /nr/insta/instance/0/max_query_interval value uint32 2678400' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'internal set modify - /nr/insta/connection_pool_size value uint16 32' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'internal set modify - /nr/insta/instance/0/max_outstanding_query  value uint16 24' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'internal set modify - /nr/insta/common/infinidb/config/querypoolsize value uint16 8' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'internal set modify - /nr/insta/instance/0/read_temptablethreshold value uint32 500' 'wr mem'"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process insta restart' 'wr mem'"
echo "Done"
done

}


function rge_addons {

for i in $gdsvzbrge1 $gdsvzbrge2
do
        $SSH $i 'echo "MaxStartups 20" >> /var/opt/tms/output/sshd_config'
        $SSH $i "$CLI -t 'en' 'conf t' 'pm process sshd restart'"
        $SSH $i "mkdir -p /data/rubix/rubix_report/"
        $SSH $i "touch /data/rubix/rubix_report/disk_mounted"
        $SSH $i "mkdir -p /data/configs/EntityConfig/"
        $SSH $i "cp /data/inputfile /opt/tms/bizreflex-bizreflex3.3/WEB-INF/classes/"
        $SSH $i "mount -o remount, rw /"
        $SSH $i 'cd /opt/tms/bizreflex-bizreflex3.3/WEB-INF/classes;/usr/bin/python TreeCacheEntries.py --60m="1h:336;3h:496;1d:62" --1h="1h:23;3h:0;1d:0;7d:0;1M:0" --1d="1d:1;7d:0;1M:0" --1w="7d:1;1M:0" --1M="1M:1" --5m="5m:35712;1h:0;3h:0;1d:0;7d:0;1M:0"'
        $SSH $i "/usr/bin/perl -pi -e 's/<maxHistory>(\S+)<\/maxHistory>/<maxHistory>30<\/maxHistory>\n\t\t\t<maxFileSize>10GB<\/maxFileSize>\n\t\t\t<\/timeBasedFileNamingAndTriggeringPolicy>/g' /opt/tms/bizreflex-bizreflex3.3/WEB-INF/classes/logback.xml"
done

}

function rubix_node_addon {

val=`$SSH $gdsvzbrub1 "$CLI -t 'en' 'sh run full'"|grep 'cluster'|grep 'expected-node'|awk '{print $NF}'`
add_val=`expr $val + 1`

echo -n "Adding new Rubix node to Rubix Cluster... "

for i in $gdsvzbrub1 $gdsvzbrub2 $gdsvzbrub3 $gdsvzbrub4 $gdsvzbrub5 $gdsvzbrub6
do
        $SSH $i "$CLI -t 'en' 'conf t' 'cluster expected-nodes $add_val'"
        $SSH $i "$CLI -t 'en' 'conf t' 'wr mem'"
done

a=`$SSH $gdsvzbrubvip "/opt/tms/bin/cli -t 'en' 'sh run full' |grep 'cluster ' | egrep 'master|interface|name|id' | grep -v auto"`

for i in $gdsvzbrub1 $gdsvzbrub2 $gdsvzbrub3 $gdsvzbrub4 $gdsvzbrub5 $gdsvzbrub6
do      
        $SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'no cluster enable' 'wr mem'"
IFS="
"
        for j in $a
        do
           	ssh -q root@$i "/opt/tms/bin/cli -t 'en' 'conf t' '$j' 'wr mem'"
        done
IFS=" "
	$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'cluster enable' 'wr mem'"
done
echo "Done"
}
