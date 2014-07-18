source env.sh

$SSH $gdsvzbcolvip '/opt/tps/bin/pmx.py subshell oozie run job master_job'
$SSH $gdsvzbcolvip '/opt/tps/bin/pmx.py subshell oozie run job second_job'
$SSH $gdsvzbcolvip '/opt/tps/bin/pmx.py subshell oozie run job exporter_master_job'
$SSH $gdsvzbcolvip '/opt/tps/bin/pmx.py subshell oozie run job rStatsjob'
$SSH $gdsvzbcolvip '/opt/tps/bin/pmx.py subshell oozie run job sessionLogsJob'
