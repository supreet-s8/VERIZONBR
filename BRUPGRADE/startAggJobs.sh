source env.sh
source master_logic.sh

$SSH $gdsvzbcolvip "/opt/tps/bin/pmx.py subshell oozie run job aggregate_1d"
$SSH $gdsvzbcolvip "/opt/tps/bin/pmx.py subshell oozie run job aggregate_1w"
$SSH $gdsvzbcolvip "/opt/tps/bin/pmx.py subshell oozie run job aggregate_1m"
$SSH $gdsvzbcolvip "/opt/tps/bin/pmx.py subshell oozie run job export_agg_1d"
$SSH $gdsvzbcolvip "/opt/tps/bin/pmx.py subshell oozie run job export_agg_1w"
$SSH $gdsvzbcolvip "/opt/tps/bin/pmx.py subshell oozie run job export_agg_1m"
