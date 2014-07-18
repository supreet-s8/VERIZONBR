
jobbool=`/opt/tps/bin/pmx.py subshell oozie show coordinator RUNNING jobs | grep upgrade_export`

if [ -z $jobbool ]
then 
/opt/tps/bin/pmx.py subshell oozie run job export_job
fi
