#!/bin/bash

source env.sh



function downgradeImage { 

host=$1
for i in $host 
do 
  echo "Downgrading image on $i"
  location=`$SSH $i "/opt/tms/bin/cli -t 'en' 'conf t' 'sh images'"  | grep -A 1 "Partition" | grep -v ^"--" | sed 'N;s/\n/ /'  | grep bizreflex3.2.rc3 | awk '{print $2}' | sed 's/://' | head -1`
  $SSH $i "/opt/tms/bin/cli -t 'en' 'conf term' 'image boot location $location' 'wr mem' " 
  echo "------- VERIFYING NEXT BOOT Image -----------"
  IMAGE=`$SSH ${i} '/opt/tms/bin/cli -t "en" "conf t" "show images" | grep "Next boot partition"' | awk '{ print $NF }'`
  echo -n "Next Boot Image on ${i} is  :  "
  $SSH ${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'show images'" | grep -A1 "Partition $IMAGE:" | tail -1 | awk '{ print $2 }'

echo " PROCEED WITH SYSTEM REBOOT "
read -p "Continue (y): "
[ "$REPLY" != "y" ] && exit 0

done
}

function reload {

node=$1

echo "Rebooting $node...."
$SSH $node "/opt/tms/bin/cli -t 'en' 'conf term' 'reload' "


}


downgradeImage $1
reload $1

