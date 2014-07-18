source env.sh

jobstart=`date "+%Y-%m-%dT00:05Z"

for i in $gdsvzbcol1 $gdsvzbcol2
do
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set job sessionLogsJob attribute jobStart $jobstart"
done
$SSH $gdsvzbcolvip "/opt/tps/bin/pmx.py subshell oozie run job sessionLogsJob"
