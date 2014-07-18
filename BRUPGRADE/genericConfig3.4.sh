source env.sh

host=$1

echo -n "Doing Generic Configuration... "
$SSH $host "mount -o remount,rw /"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'no virt enable' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'no pm process insta launch enable' 'wr mem'"
echo "Done"
