source env.sh

for host in $gdsvzbinsnew1 $gdsvzbinsnew2
do
echo -n "Doing Generic Configuration on $host... "
ssh admin@$host 2>/dev/null << EOF
en
conf t
license install LK2-RESTRICTED_CMDS-88A4-FNLG-XCAU-U
no virt enable
no username root disable
user admin password Gu@vuSgb5
user root password Gu@vuSgb5
ip host BR701-COL-001 108.55.163.56
ip host BR701-COL-002 108.55.163.26
ip host BR701-CMP-001 108.55.163.41
ip host BR701-CMP-002 108.55.163.42
ip host BR701-CMP-003 108.55.163.43
ip host BR701-CMP-004 108.55.163.44
ip host BR701-CMP-005 108.55.163.45
ip host BR701-CMP-006 108.55.163.46
ip host BR701-CMP-007 108.55.163.57
ip host BR701-CMP-008 108.55.163.58
ip host BR701-CMP-009 108.55.163.59
ip host BR701-CMP-010 108.55.163.63
ip host BR701-CMP-011 108.55.163.66
ip host BR701-CMP-012 108.55.163.67
ip host BR701-CMP-013 108.55.163.68
ip host BR701-INST-001 108.55.163.60
ip host BR701-INST-002 108.55.163.29
ip host BR701-RGE-001 108.55.163.70
ip host BR701-RGE-002 108.55.163.31
ip host BR701-RUB-001 108.55.163.85
ip host BR701-RUB-002 108.55.163.86
ip host BR701-RUB-003 108.55.163.87
ip host BR701-RUB-004 108.55.163.88
ip host BR701-RUB-005 108.55.163.89
ip host BR701-COL-HA 108.55.163.75
ip host BR701-INST-HA 108.55.163.76
ip host BR701-RUB-HA 108.55.163.77
ip host BR701-RGE-HA 108.55.163.84
ip host bizreflex.701.verizon.net 108.55.163.77
ip host bizreflex.n701.verizon.net 108.55.163.77
ip host bizreflex.703.verizon.net 108.55.163.80
ip host bizreflex.n703.verizon.net 108.55.163.80
ip host bizreflex.702.verizon.net 108.55.163.83
ip host bizreflex.n702.verizon.net 108.55.163.83
ip host analytics.701.verizon.net 108.55.163.84
ip host analytics.702.verizon.net 108.55.163.84
ip host analytics.703.verizon.net 108.55.163.84
ip host analytics.n701.verizon.net 108.55.163.84
ip host analytics.n702.verizon.net 108.55.163.84
ip host analytics.n703.verizon.net 108.55.163.84
ip host mx1.guavus.com 204.232.241.167
ip host nsiressmtp01.resva.vmnocam.com 108.55.160.80
no ntp disable
no ntp disable
ntp server 10.0.250.199 disable
ntp server 10.0.250.199 version 4
ntp server 10.0.250.200 disable
ntp server 10.0.250.200 version 4
no ntp server 108.55.161.56 disable
ntp server 108.55.161.56 version 4
no ntp server 108.55.161.57 disable
ntp server 108.55.161.57 version 4
wr mem
_shell
mount -o remount,rw /
EOF
echo "Done"
done
