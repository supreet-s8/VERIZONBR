#!/bin/bash
source env.sh
function configure_Job {

echo "------------ Configure Upgrade Prefix job------------"
for i in $gdsvzbcol1 $gdsvzbcol2
do
$SSH $i "/opt/tps/bin/pmx.py subshell oozie add dataset upg_prefix_ds_out"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset upg_prefix_ds_out attribute path /data/BR_OUT/PrefixJob/%Y/%M/%D/%H/"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset upg_prefix_ds_out attribute pathType hdfs"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset upg_prefix_ds_out attribute startOffset 1"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset upg_prefix_ds_out attribute frequency 60"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset upg_prefix_ds_out attribute frequencyUnit minute"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset upg_prefix_ds_out attribute endOffset 1"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset upg_prefix_ds_out attribute outputOffset 1"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset upg_prefix_ds_out attribute doneFile _DONE"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set dataset upg_prefix_ds_out attribute startTime 2012-01-03T00:00Z"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie add job upgrade_prefix_job BizreflexPrefixJob /opt/etc/oozie/BizreflexPrefixCubes"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set job upgrade_prefix_job attribute jobStart 2012-11-02T20:00Z"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set job upgrade_prefix_job attribute jobFrequency 60"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set job upgrade_prefix_job attribute jobEnd 2013-11-07T11:00Z"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set job upgrade_prefix_job attribute frequencyUnit minute"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set job upgrade_prefix_job action ExecutePrefixJob attribute jarFile /opt/tms/java/CubeCreator-upgrade.jar"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set job upgrade_prefix_job action ExecutePrefixJob attribute mainClass com.guavus.mapred.reflex.bizreflex.job.PrefixAsJob.PrefixAsCubes"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set job upgrade_prefix_job action ExecutePrefixJob attribute configFile /data/configs/jobs/config_bizrules_upgrade.xml"
$SSH $i "/opt/tps/bin/pmx.py subshell oozie set job upgrade_prefix_job action ExecutePrefixJob attribute outputDataset upg_prefix_ds_out"
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'wr mem'"

done

}
configure_Job
