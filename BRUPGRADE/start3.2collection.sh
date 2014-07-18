source env.sh

host=$gdsvzbcolvip

echo -n "Starting Samplicator on $host... "
$SSH $host "/opt/tms/bin/samplicate -f /data/configs/samplicate.cfg"
echo "Done"

echo -n "Starting Collector on $host... "
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process collector restart' 'wr me'"
echo "Done"
