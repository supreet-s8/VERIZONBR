
source env.sh

function setbootlocation {

echo ""
echo "Activating New Image ( BR3.4.rc2 )"
for i in $gdsvzbrub1 $gdsvzbrub2 $gdsvzbrub3 $gdsvzbrub4 $gdsvzbrub5
do
	echo "Activating 3.4 rc2 Image on ${i}   "
	$SSH ${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'image boot next' 'wr mem'"
done


echo ""
echo "------- VERIFYING NEXT BOOT Image -----------"
for i in $gdsvzbrub1 $gdsvzbrub2 $gdsvzbrub3 $gdsvzbrub4 $gdsvzbrub5
do
	
	IMAGE=`$SSH ${i} '/opt/tms/bin/cli -t "en" "conf t" "show images" | grep "Next boot partition"' | awk '{ print $NF }'`
	echo -n "Next Boot Image on ${i} is  :  "
	$SSH ${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'show images'" | grep -A1 "Partition $IMAGE:" | tail -1 | awk '{ print $2 }'

done

echo " PROCEED WITH SYSTEM REBOOT "
read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0

}

function reload {

nodes=$1
node1=`echo $nodes|awk -F"," '{print $1}'`
node2=`echo $nodes|awk -F"," '{print $2}'`
node3=`echo $nodes|awk -F"," '{print $3}'`

echo "Rebooting $node1...."
$SSH $node1 "/opt/tms/bin/cli -t 'en' 'conf term' 'reload' "

echo "Rebooting $node2...."
$SSH $node2 "/opt/tms/bin/cli -t 'en' 'conf term' 'reload' "

echo "Rebooting $node3...."
$SSH $node2 "/opt/tms/bin/cli -t 'en' 'conf term' 'reload' "

}

setbootlocation
reload $gdsvzbrub1,$gdsvzbrub2,$gdsvzbrub3
echo "Sleeping for 15 mins ...."
sleep 900
reload $gdsvzbrub4,$gdsvzbrub5 
