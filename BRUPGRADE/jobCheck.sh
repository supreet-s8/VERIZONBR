source env.sh
source master_logic.sh

jobname=$1
jobid=`$SSH $gdsvzbcolvip "/opt/tms/bin/pmx subshell oozie 'show workflow RUNNING jobs'" | grep ^[0-9] | grep $jobname | awk '{print $1}'`
echo "Failed or Invalid paths:"
echo "----------------------------------"
echo " "

$SSH $gdsvzbcolvip "cd oozie-admi/$jobid; grep -i invalid */*.stdout; grep -i fail */*.stdout"


echo "Map-Reduce Progress:"
echo "-----------------------------------"
echo " "

$SSH $gdsvzbcolvip "cd oozie-admi/$jobid; tail -f */*.stderr" 
