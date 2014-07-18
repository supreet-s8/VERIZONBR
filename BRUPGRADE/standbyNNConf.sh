source env.sh
source master_logic.sh

function postboot {

   echo "Mounting Disk on NameNode $gdsvzbcol2 ------"
   $SSH $gdsvzbcol2 "/bin/mount -o remount,rw /"
   tps_fs $gdsvzbcol2 1
   $SSH $gdsvzbcol2 "/bin/df -h | grep -w mapper"
   echo " "
   $SSH $gdsvzbcol2 "sed -i '/\/configuration>/i<property>\n    <name>mapred.task.timeout</name>\n    <value>3600000</value>\n    <description></description>\n</property>' /opt/samples/hadoop_conf/mapred-site.xml.template"
   $SSH $gdsvzbcol2 "sed -i '/\/configuration>/i<property>\n    <name>mapred.task.timeout</name>\n    <value>3600000</value>\n    <description></description>\n</property>' /opt/hadoop/conf/mapred-site.xml"

}

postboot
col_settings $gdsvzbcol2
samplicator $gdsvzbcol2
logdownloader $gdsvzbcol2
RE_process $gdsvzbcol2
