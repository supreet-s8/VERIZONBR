source env.sh

name1=iqn.1994-05.com.redhat:gds-vzb-rub1
name2=iqn.1994-05.com.redhat:gds-vzb-rub2
name3=iqn.1994-05.com.redhat:gds-vzb-rub3
name4=iqn.1994-05.com.redhat:gds-vzb-rub4

$SSH $gdsvzbrub1 "/opt/tms/bin/cli -t en 'conf t' 'tps iscsi initiator-name $name1' 'wr mem'"
$SSH $gdsvzbrub2 "/opt/tms/bin/cli -t en 'conf t' 'tps iscsi initiator-name $name2' 'wr mem'"
$SSH $gdsvzbrub3 "/opt/tms/bin/cli -t en 'conf t' 'tps iscsi initiator-name $name3' 'wr mem'"
$SSH $gdsvzbrub4 "/opt/tms/bin/cli -t en 'conf t' 'tps iscsi initiator-name $name4' 'wr mem'"
