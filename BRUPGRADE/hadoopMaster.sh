source env.sh

node1=56
node2=26
prefix=108.55.163.
host=`echo $1 | awk -F"." '{print $NF}'`

echo "Current Master Node"
echo "---------------------"

$SSH root@${gdsvzbcolvip} "/opt/tms/bin/cli -t en 'sh cluster global' | grep -B 1 'Node Role: master'"


echo " "
echo -n "Making $1 Master... "


if [ $host -eq $node1 ]
then
$SSH root@${prefix}${node2} "/opt/tms/bin/cli -t 'en' 'conf t' 'no cluster enable' 'wr mem'"
else
$SSH root@${prefix}${node1} "/opt/tms/bin/cli -t 'en' 'conf t' 'no cluster enable' 'wr mem'"
fi
echo "Done"

ssh-keygen -qR ${gdsvzbcolvip}
echo "New Master Node"
echo "---------------------"

$SSH root@${gdsvzbcolvip} "/opt/tms/bin/cli -t en 'sh cluster global' | grep -B 1 'Node Role: master'"
