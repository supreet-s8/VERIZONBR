source env.sh

host=$1

echo -n "Enabling Cluster on $host ... "

$SSH root@${host} "/opt/tms/bin/cli -t 'en' 'conf t' 'cluster enable' 'wr mem'"

echo "Done"
