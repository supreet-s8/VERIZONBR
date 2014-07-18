source env.sh

backupdb1wwid=`$SSH ${gdsvzbinsnewvip} "/sbin/multipath -ll" | grep backupdbroot1 | awk '{print $2}' | sed -e 's/(//g' -e 's/)//g'`
backupdb2wwid=`$SSH ${gdsvzbinsnewvip} "/sbin/multipath -ll" | grep backupdbroot2 | awk '{print $2}' | sed -e 's/(//g' -e 's/)//g'`
backupdb3wwid=`$SSH ${gdsvzbinsnewvip} "/sbin/multipath -ll" | grep backupdbroot3 | awk '{print $2}' | sed -e 's/(//g' -e 's/)//g'`
backupdb4wwid=`$SSH ${gdsvzbinsnewvip} "/sbin/multipath -ll" | grep backupdbroot4 | awk '{print $2}' | sed -e 's/(//g' -e 's/)//g'`

uuid1=`$SSH ${gdsvzbinsnewvip} "/sbin/blkid" | grep backupdbroot1 | head -1 | awk '{print $3}' | awk -F"=" '{print $2}' | sed 's/"//g'`
uuid2=`$SSH ${gdsvzbinsnewvip} "/sbin/blkid" | grep backupdbroot2 | head -1 | awk '{print $3}' | awk -F"=" '{print $2}' | sed 's/"//g'`
uuid3=`$SSH ${gdsvzbinsnewvip} "/sbin/blkid" | grep backupdbroot3 | head -1 | awk '{print $3}' | awk -F"=" '{print $2}' | sed 's/"//g'`
uuid4=`$SSH ${gdsvzbinsnewvip} "/sbin/blkid" | grep backupdbroot4 | head -1 | awk '{print $3}' | awk -F"=" '{print $2}' | sed 's/"//g'`

for host in $gdsvzbinsnew1 $gdsvzbinsnew2
do
echo -n "Doing Backup dbroots Configuration on node $host... "
$SSH $host "/bin/mkdir -p /usr/local/Calpont/backup/data1"
$SSH $host "/bin/mkdir -p /usr/local/Calpont/backup/data2"
$SSH $host "/bin/mkdir -p /usr/local/Calpont/backup/data3"
$SSH $host "/bin/mkdir -p /usr/local/Calpont/backup/data4"

$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'mpio multipaths alias backupdbroot1 wwid $backupdb1wwid' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'mpio multipaths alias backupdbroot2 wwid $backupdb2wwid' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'mpio multipaths alias backupdbroot3 wwid $backupdb3wwid' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'mpio multipaths alias backupdbroot4 wwid $backupdb4wwid' 'wr mem'"

$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot1 uuid $uuid1' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot1 wwid $backupdb1wwid' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot1 mount-point /usr/local/Calpont/backup/data1/' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot1 mount-option mount-if-master' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot1 enable' 'wr mem'"

$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot2 uuid $uuid2' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot2 wwid $backupdb2wwid' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot2 mount-point /usr/local/Calpont/backup/data2/' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot2 mount-option mount-if-master' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot2 enable' 'wr mem'"

$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot3 uuid $uuid3' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot3 wwid $backupdb3wwid' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot3 mount-point /usr/local/Calpont/backup/data3/' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot3 mount-option mount-if-master' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot3 enable' 'wr mem'"

$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot4 uuid $uuid4' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot4 wwid $backupdb4wwid' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot4 mount-point /usr/local/Calpont/backup/data4/' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot4 mount-option mount-if-master' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs backupdbroot4 enable' 'wr mem'"

$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'job 3 command 1 \"insta infinidb disk-mgmt backup\"' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'job 3 schedule daily time 01:00:00' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'job 3 enable' 'wr mem'"

echo "Done"
done

echo " "
echo "Jobs configured on Insta nodes..."
$SSH $gdsvzbinsnewvip "/opt/tms/bin/cli -t 'en' 'conf t' 'show jobs'"
