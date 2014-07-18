source env.sh

function iphostmap {

host=$1
echo "en" > $PWD/$host.hostmap
echo "conf t" >> $PWD/$host.hostmap
$SSH root@${host} "/opt/tms/bin/cli -t 'en' 'sh run full' | grep 'ip host' | grep -v localhost" | sed 's/   ip/no ip/g' >> $PWD/$host.hostmap
echo "ip host BR701-COL-001 108.55.163.56" >> $PWD/$host.hostmap
echo "ip host BR701-COL-002 108.55.163.26" >> $PWD/$host.hostmap
echo "ip host BR701-CMP-001 108.55.163.41" >> $PWD/$host.hostmap
echo "ip host BR701-CMP-002 108.55.163.42" >> $PWD/$host.hostmap
echo "ip host BR701-CMP-003 108.55.163.43" >> $PWD/$host.hostmap
echo "ip host BR701-CMP-004 108.55.163.44" >> $PWD/$host.hostmap
echo "ip host BR701-CMP-005 108.55.163.45" >> $PWD/$host.hostmap
echo "ip host BR701-CMP-006 108.55.163.46" >> $PWD/$host.hostmap
echo "ip host BR701-CMP-007 108.55.163.57" >> $PWD/$host.hostmap
echo "ip host BR701-CMP-008 108.55.163.58" >> $PWD/$host.hostmap
echo "ip host BR701-CMP-009 108.55.163.59" >> $PWD/$host.hostmap
echo "ip host BR701-CMP-010 108.55.163.63" >> $PWD/$host.hostmap
echo "ip host BR701-CMP-011 108.55.163.66" >> $PWD/$host.hostmap
echo "ip host BR701-CMP-012 108.55.163.67" >> $PWD/$host.hostmap
echo "ip host BR701-CMP-013 108.55.163.68" >> $PWD/$host.hostmap
echo "ip host BR701-INST-001 108.55.163.60" >> $PWD/$host.hostmap
echo "ip host BR701-INST-002 108.55.163.29" >> $PWD/$host.hostmap
echo "ip host BR701-INSTA-001 108.55.163.91" >> $PWD/$host.hostmap
echo "ip host BR701-INSTA-002 108.55.163.92" >> $PWD/$host.hostmap
echo "ip host BR701-RGE-001 108.55.163.70" >> $PWD/$host.hostmap
echo "ip host BR701-RGE-002 108.55.163.31" >> $PWD/$host.hostmap
echo "ip host BR701-RUB-001 108.55.163.85" >> $PWD/$host.hostmap
echo "ip host BR701-RUB-002 108.55.163.86" >> $PWD/$host.hostmap
echo "ip host BR701-RUB-003 108.55.163.87" >> $PWD/$host.hostmap
echo "ip host BR701-RUB-004 108.55.163.88" >> $PWD/$host.hostmap
echo "ip host BR701-RUB-005 108.55.163.89" >> $PWD/$host.hostmap
echo "ip host BR701-RUB-006 108.55.163.90" >> $PWD/$host.hostmap
echo "ip host BR701-COL-HA 108.55.163.75" >> $PWD/$host.hostmap
echo "ip host BR701-INST-HA 108.55.163.76" >> $PWD/$host.hostmap
echo "ip host BR701-RUB-HA 108.55.163.77" >> $PWD/$host.hostmap
echo "ip host BR701-RGE-HA 108.55.163.84" >> $PWD/$host.hostmap
echo "ip host BR701-INSTA-HA 108.55.163.93" >> $PWD/$host.hostmap
echo "ip host bizreflex.701.verizon.net 108.55.163.77" >> $PWD/$host.hostmap
echo "ip host bizreflex.n701.verizon.net 108.55.163.77" >> $PWD/$host.hostmap
echo "ip host bizreflex.703.verizon.net 108.55.163.80" >> $PWD/$host.hostmap
echo "ip host bizreflex.n703.verizon.net 108.55.163.80" >> $PWD/$host.hostmap
echo "ip host bizreflex.702.verizon.net 108.55.163.83" >> $PWD/$host.hostmap
echo "ip host bizreflex.n702.verizon.net 108.55.163.83" >> $PWD/$host.hostmap
echo "ip host analytics.701.verizon.net 108.55.163.84" >> $PWD/$host.hostmap
echo "ip host analytics.702.verizon.net 108.55.163.84" >> $PWD/$host.hostmap
echo "ip host analytics.703.verizon.net 108.55.163.84" >> $PWD/$host.hostmap
echo "ip host analytics.n701.verizon.net 108.55.163.84" >> $PWD/$host.hostmap
echo "ip host analytics.n702.verizon.net 108.55.163.84" >> $PWD/$host.hostmap
echo "ip host analytics.n703.verizon.net 108.55.163.84" >> $PWD/$host.hostmap
echo "ip host mx1.guavus.com 204.232.241.167" >> $PWD/$host.hostmap
echo "ip host nsiressmtp01.resva.vmnocam.com 108.55.160.80" >> $PWD/$host.hostmap
hostname=`cat $PWD/$host.hostmap | grep $host | grep ^ip | awk '{print $3}'`
echo "hostname $hostname" >> $PWD/$host.hostmap
echo "wr me" >> $PWD/$host.hostmap
scp -q $PWD/$host.hostmap root@$host:/var/home/root/
$SSH root@${host} "$CLI < /var/home/root/$host.hostmap"

}

iphostmap $1 $2
echo -n "Removing old hostmap entries on node $1..."
sleep 5
echo " Done"
echo -n "Applying new hostmap entries on node $1..."
sleep 5
echo " Done"
echo " "
