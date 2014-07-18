source env.sh
source master_logic.sh

job1=`cat $PWD/jobtime.txt | sed 's/[A-Z]/ /'`
job2=`date --date="$job1" +%s`
job3=`expr $job2 + 3600`
jobend=`date -d@$job3 "+%FT%H:%MZ"`

echo "/opt/tps/bin/pmx.py subshell oozie set job upgrade_prefix_job attribute jobStart 2014-06-01T01:00Z" > $PWD/jobs/upgrade-job.sh
echo "/opt/tps/bin/pmx.py subshell oozie set job bizrules_upgrade attribute jobStart 2014-06-01T01:00Z" >> $PWD/jobs/upgrade-job.sh
echo "/opt/tps/bin/pmx.py subshell oozie set job upgrade_export_job attribute jobStart 2014-06-01T01:00Z" >> $PWD/jobs/upgrade-job.sh
echo "/opt/tps/bin/pmx.py subshell oozie set job upgrade_prefix_job attribute jobEnd $jobend" >> $PWD/jobs/upgrade-job.sh
echo "/opt/tps/bin/pmx.py subshell oozie set job bizrules_upgrade attribute jobEnd $jobend" >> $PWD/jobs/upgrade-job.sh
echo "/opt/tps/bin/pmx.py subshell oozie set job upgrade_export_job attribute jobEnd $jobend" >> $PWD/jobs/upgrade-job.sh
echo "/opt/tps/bin/pmx.py subshell oozie set job aggregate_1d attribute jobStart 2014-06-02T05:00Z" >> $PWD/jobs/upgrade-job.sh
echo "/opt/tps/bin/pmx.py subshell oozie set job export_agg_1d attribute jobStart 2014-06-02T05:00Z" >> $PWD/jobs/upgrade-job.sh
echo "/opt/tps/bin/pmx.py subshell oozie set job aggregate_1w attribute jobStart 2014-06-08T05:00Z" >> $PWD/jobs/upgrade-job.sh
echo "/opt/tps/bin/pmx.py subshell oozie set job export_agg_1w attribute jobStart 2014-06-08T05:00Z" >> $PWD/jobs/upgrade-job.sh
echo "/opt/tps/bin/pmx.py subshell oozie set job aggregate_1m attribute jobStart 2014-07-01T05:00Z" >> $PWD/jobs/upgrade-job.sh
echo "/opt/tps/bin/pmx.py subshell oozie set job export_agg_1m attribute jobStart 2014-07-01T05:00Z" >> $PWD/jobs/upgrade-job.sh
chmod u+x $PWD/jobs/upgrade-job.sh

for i in $gdsvzbcol1 $gdsvzbcol2
do
scp -q $PWD/jobs/upgrade-job.sh root@${i}:/data/IBS/
$SSH $i "/data/IBS/upgrade-job.sh"
done

$SSH $gdsvzbcolvip "/opt/tps/bin/pmx.py subshell oozie run job upgrade_prefix_job"
$SSH $gdsvzbcolvip "/opt/tps/bin/pmx.py subshell oozie run job bizrules_upgrade"

