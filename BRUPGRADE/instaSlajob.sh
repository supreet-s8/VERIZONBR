source env.sh

for host in $gdsvzbinsnew1 $gdsvzbinsnew2
do
echo -n "SLA job configuration on node $host... "
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'job 2 command 1 \"insta delete-with-retention instance-id 0 bin-class 1dAggr bin-type * aggr -1 retention-period 9552\"' 'wr mem'" 
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'job 2 command 2 \"insta delete-with-retention instance-id 0 bin-class 1hAggr bin-type * aggr -1 retention-period 9552\"' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'job 2 command 3 \"insta delete-with-retention instance-id 0 bin-class 1mAggr bin-type * aggr -1 retention-period 9552\"' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'job 2 command 4 \"insta delete-with-retention instance-id 0 bin-class 1wAggr bin-type * aggr -1 retention-period 9552\"' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'job 2 command 5 \"insta delete-with-retention instance-id 0 bin-class INSTATIME_60min bin-type * aggr -1 retention-period 9552\"' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'job 2 command 6 \"insta delete-with-retention instance-id 0 bin-class NPENTITY_60min bin-type * aggr -1 retention-period 9552\"' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'job 2 command 7 \"insta delete-with-retention instance-id 0 bin-class SLA_5min bin-type * aggr -1 retention-period 9552\"' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'job 2 schedule type daily' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'job 2 schedule daily time 03:00:00' 'wr mem'"
$SSH $host "/opt/tms/bin/cli -t 'en' 'conf t' 'job 2 enable' 'wr mem'"
echo "Done"
done
