source env.sh
source master_logic.sh

job1=`cat $PWD/jobtime.txt | sed 's/[A-Z]/ /'`
job2=`date --date="$job1" +%s`
job3=`expr $job2 + 3600`
jobend=`date -d@$job3 "+%FT%H:%MZ"`

echo "/opt/tps/bin/pmx.py subshell oozie set job bizrules_job attribute jobStart $jobend" > $PWD/jobs/biz-job.sh
chmod u+x $PWD/jobs/biz-job.sh

for i in $gdsvzbcol1 $gdsvzbcol2
do
scp -q $PWD/jobs/biz-job.sh root@${i}:/data/IBS/
$SSH $i "/data/IBS/biz-job.sh"
done

$SSH $gdsvzbcolvip "/opt/tps/bin/pmx.py subshell oozie run job bizrules_job"
