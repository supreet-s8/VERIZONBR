source env.sh
source master_logic.sh

function postboot {
for node in $gdsvzbcmp1 $gdsvzbcmp2 $gdsvzbcmp3 $gdsvzbcmp4 $gdsvzbcmp5 $gdsvzbcmp6 $gdsvzbcmp7 $gdsvzbcmp8 $gdsvzbcmp9 $gdsvzbcmp10 $gdsvzbcmp11 $gdsvzbcmp12 $gdsvzbcmp13
do
   echo "Mounting Disk on DataNode $node ------"
   $SSH $node "/bin/mount -o remount,rw /"
   tps_fs $node 1
   $SSH $node "/bin/df -h | grep -w mapper"
   echo " "
   $SSH $node "sed -i '/\/configuration>/i<property>\n    <name>mapred.task.timeout</name>\n    <value>3600000</value>\n    <description></description>\n</property>' /opt/samples/hadoop_conf/mapred-site.xml.template"
   $SSH $node "sed -i '/\/configuration>/i<property>\n    <name>mapred.task.timeout</name>\n    <value>3600000</value>\n    <description></description>\n</property>' /opt/hadoop/conf/mapred-site.xml"
done
}

postboot
