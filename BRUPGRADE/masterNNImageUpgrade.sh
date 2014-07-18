source env.sh
source master_logic.sh

function setbootlocation {

echo ""
echo "Activating New Image ( BR3.4.rc2 )"

	echo "Activating 3.4 rc2 Image on $gdsvzbcol1   "
	$SSH $gdsvzbcol1 "/opt/tms/bin/cli -t 'en' 'conf t' 'image boot next' 'wr mem'"


echo ""
echo "------- VERIFYING NEXT BOOT Image -----------"

	IMAGE=`$SSH $gdsvzbcol1 '/opt/tms/bin/cli -t "en" "conf t" "show images" | grep "Next boot partition"' | awk '{ print $NF }'`
	echo -n "Next Boot Image on $gdsvzbcol1 is  :  "
	$SSH $gdsvzbcol1 "/opt/tms/bin/cli -t 'en' 'conf t' 'show images'" | grep -A1 "Partition $IMAGE:" | tail -1 | awk '{ print $2 }'

echo " PROCEED WITH SYSTEM REBOOT "
read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0

}

function reload {

  echo "Rebooting $gdsvzbcol1...."
  $SSH $gdsvzbcol1 "/opt/tms/bin/cli -t 'en' 'conf term' 'reload' "

}


setbootlocation
reload
