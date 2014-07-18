source env.sh

echo -n "Setting Cron for Exporter Job... "
$SSH $gdsvzbcolvip "mkdir -p /data/scripts/ 2> /dev/null"
scp -q $PWD/startExporter.sh root@${gdsvzbcolvip}:/data/scripts/
scp -q $PWD/jobtime.txt root@${gdsvzbcolvip}:/data/scripts/

$SSH $gdsvzbcolvip 'echo "* */2 * * * /data/scripts/startExporter.sh 2> /dev/null" | crontab -'
echo "Done"
