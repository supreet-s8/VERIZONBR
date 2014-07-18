source master_logic.sh

insta_config
$SSH $gdsvzbinsnewvip "/opt/tms/bin/cli -t 'en' 'conf t' 'insta infinidb install'"
while [ true ]
do
clear
echo "Infinidb Install in Progress.."
echo " "
$SSH $gdsvzbinsnewvip "/opt/tms/bin/cli -t 'en' 'conf t' 'insta infinidb get-status-info'"  | grep -A 5 "Infinidb Install status"
echo " "
echo "Sleeping for 15 mins. Will check progress post that..."
echo "Hit Ctrl+C once insta is in RUNNING state and infinidb is INSTALLED"
sleep 900
done
