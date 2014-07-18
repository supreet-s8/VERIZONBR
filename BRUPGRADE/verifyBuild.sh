source env.sh

host=$1

echo -n "Version on $host   "
$SSH $host "/opt/tms/bin/cli -t 'en' 'show ver' " | grep "Build ID" || echo ""

