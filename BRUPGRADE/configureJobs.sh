#!/bin/bash

source env.sh
source master_logic.sh

rem_old_jobs
cp_job_config
rem_old_gleaning
copy_files

echo "--------- Configuring Oozie Jobs ---------"

for i in $gdsvzbcol1 $gdsvzbcol2
do
scp -qr $PWD/jobs root@${i}:/data/
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/prefix_upgrade_job.cli"
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/bizrules_upgrade_job.cli"
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/export_upgrade_job.cli"
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/onetimepotASjob.cli"
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/masterjob.cli"
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/bizrulesjob.cli"
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/exportjob.cli"
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/1daggjob.cli"
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/1dexpjob.cli"
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/1waggjob.cli"
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/1wexpjob.cli"
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/1maggjob.cli"
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/1mexpjob.cli"
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/unrolledAggjob.cli"
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/potASjob.cli"
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/whiteaslistjob.cli"
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/sessionjob.cli"
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/sla1.cli"
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/sla2.cli"
$SSH ${i} "/opt/tms/bin/cli -x -h /data/jobs/slamr.cli"
done

echo "Following Jobs Configured .... "
echo "Prefix Upgrade Job"
echo "Bizrules Upgrade Job"
echo "Export Upgrade Job"
echo "OneTime Potential AS Job"
echo "Master Job"
echo "Bizrules Job"
echo "Export Job"
echo "1 day Agg Job"
echo "1 day Agg Exp Job"
echo "1 week Agg Job"
echo "1 week Agg Exp Job"
echo "1 month Agg Job"
echo "1 month Agg Exp Job"
echo "Unrolled Agg Job"
echo "Potential AS Job"
echo "WhiteAsList Job"
echo "SessionLogs Job"
echo "SLA1"
echo "SLA2"
echo "SLAMR"

