source env.sh
source master_logic.sh

function postboot {

   echo "------ Mounting Disk on NameNode $gdsvzbcol1 ------"
   $SSH $gdsvzbcol1 "/bin/mount -o remount,rw /"
   tps_fs $gdsvzbcol1 1
   $SSH $gdsvzbcol1 "/bin/df -h | grep -w mapper"
   echo " "
   $SSH $gdsvzbcol1 "sed -i '/\/configuration>/i<property>\n    <name>mapred.task.timeout</name>\n    <value>3600000</value>\n    <description></description>\n</property>' /opt/samples/hadoop_conf/mapred-site.xml.template"
   $SSH $gdsvzbcol1 "sed -i '/\/configuration>/i<property>\n    <name>mapred.task.timeout</name>\n    <value>3600000</value>\n    <description></description>\n</property>' /opt/hadoop/conf/mapred-site.xml"
   echo "------ Transferring Hadoop files to Datanodes ------"
   for i in $gdsvzbcmp1 $gdsvzbcmp2 $gdsvzbcmp3 $gdsvzbcmp4 $gdsvzbcmp5 $gdsvzbcmp6 $gdsvzbcmp7 $gdsvzbcmp8 $gdsvzbcmp9 $gdsvzbcmp10 $gdsvzbcmp11 $gdsvzbcmp12 $gdsvzbcmp13
   do
      $SSH $gdsvzbcol1 "scp -q /opt/hadoop/conf/* root@${i}:/opt/hadoop/"
   done
}

postboot
col_settings $gdsvzbcol1
samplicator $gdsvzbcol1
logdownloader $gdsvzbcol1
RE_process $gdsvzbcol1
