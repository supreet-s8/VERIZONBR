source env.sh

for host in $gdsvzbinsnew1 $gdsvzbinsnew2
do
echo -n "Adding node $host to cluster... "
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'cluster id BRINSTA701' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'cluster name GVS-BRINSTA-701' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'cluster interface b0' 'wr mem'" 
### Change eth0 to b0 for production
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'cluster master interface b0' 'wr mem'"
### Change eth0 to b0 for prod
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'cluster expected-nodes 2' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'cluster master address vip 108.55.163.93 /25' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'cluster enable' 'wr mem'"
echo "Done"
done

$SSH $gdsvzbinsnewvip "/opt/tms/bin/cli -t en 'sh cluster global' | egrep 'Hostname|Role'"
