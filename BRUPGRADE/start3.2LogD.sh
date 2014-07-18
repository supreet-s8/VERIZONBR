source env.sh

for host in $gdsvzbcol1 $gdsvzbcol2
do
echo -n "Starting LogDownloader on $host... "
$SSH $host "/opt/samples/bizreflex-rubix-config/logdownloader/logDownloader.sh /opt/samples/bizreflex-rubix-config/logdownloader/tcp.xml /opt/samples/bizreflex-rubix-config/logdownloader/config.xml &"
echo "Done"
done
