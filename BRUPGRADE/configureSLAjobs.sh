source env.sh
source master_logic.sh

asib_ts=`$SSH $gdsvzbcolvip "$HADOOP dfs -ls /data/routing/asib" | head -2 | tail -1 | awk '{print $6"T"$7"Z"}'`
eib_ts=`$SSH $gdsvzbcolvip "$HADOOP dfs -ls /data/routing/eib" | head -2 | tail -1 | awk '{print $6"T"$7"Z"}'`
mergedasib_ts=`$SSH $gdsvzbcolvip "$HADOOP dfs -ls /data/routing/merged_asib" | head -2 | tail -1 | awk '{print $6"T"$7"Z"}'`
pop_ts=`$SSH $gdsvzbcolvip "$HADOOP dfs -ls /data/routing/pop" | head -2 | tail -1 | awk '{print $6"T"$7"Z"}'`
gleaning_ts=`$SSH $gdsvzbcolvip "$HADOOP dfs -ls /data/_BizreflexCubes/Gleaning" | head -2 | tail -1 | awk '{print $6"T"$7"Z"}'`
bview_file=`$SSH $gdsvzbcolvip "cd /data/routing/bgp/tables/; ls -lrt * | grep bview | head -1 " |  awk '{print $9}' `
bview_ts=`$SSH $gdsvzbcolvip "cd /data/routing/bgp/tables/; stat $bview_file " | grep Change | awk '{print $2"T"$3}' | awk -F":" '{print $1":"$2"Z"}'`
month=`date "+%Y/%m"`
netflow_ts=`$SSH $gdsvzbcolvip "$HADOOP dfs -ls /data/netflow/$month" |  grep ^d | head -1 | awk '{print $8}' | awk -F"/" '{print $4"-"$5"-"$6"T00:00Z"}'`
today_date=`date --date="1 day" "+%Y-%m-%dT00:00Z"`

for i in $gdsvzbcol1 $gdsvzbcol2
do
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset asib attribute startTime $asib_ts"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset eib attribute startTime $eib_ts"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset merged_ib_binary attribute startTime $mergedasib_ts"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset pop attribute startTime $pop_ts"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset gleaning attribute startTime $gleaning_ts"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset bgpdumps attribute startTime $bview_ts"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset netflow attribute startTime $netflow_ts"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset master_mr attribute startTime 2014-06-01T00:00Z"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset prefix_mr attribute startTime 2014-06-01T00:00Z"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset bizrules_mr attribute startTime 2014-06-01T00:00Z"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset topint_mr attribute startTime 2014-06-01T00:00Z"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset topas_mr attribute startTime 2014-06-01T00:00Z"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset bizrules1d_mr attribute startTime 2014-06-01T00:00Z"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset bizrules1w_mr attribute startTime 2014-06-01T00:00Z"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset bizrules1m_mr attribute startTime 2014-06-01T00:00Z"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset topint1d_mr attribute startTime 2014-06-01T00:00Z"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset topint1w_mr attribute startTime 2014-06-01T00:00Z"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset topint1m_mr attribute startTime 2014-06-01T00:00Z"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset topas1d_mr attribute startTime 2014-06-01T00:00Z"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset topas1w_mr attribute startTime 2014-06-01T00:00Z"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset topas1m_mr attribute startTime 2014-06-01T00:00Z"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set job sla1 attribute jobStart $today_date"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set job sla2 attribute jobStart $today_date"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set job slamr attribute jobStart $today_date"
done

echo "Starting SLA Jobs.."
$SSH $gdsvzbcolvip "/opt/tps/bin/pmx.py subshell oozie run job sla1"
$SSH $gdsvzbcolvip "/opt/tps/bin/pmx.py subshell oozie run job sla2"
$SSH $gdsvzbcolvip "/opt/tps/bin/pmx.py subshell oozie run job slamr"

