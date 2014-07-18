source env.sh
source master_logic.sh

$SSH $gdsvzbcolvip "/opt/tps/bin/pmx.py subshell oozie run job upgrade_export_job"
