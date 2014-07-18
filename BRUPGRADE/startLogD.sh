source env.sh

for i in $gdsvzbcol2 $gdsvzbcol1
do
echo -n "Starting LogDownloader on host $i... "
$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'pm process log_downloader restart' 'wr me'"
echo "Done"
done
