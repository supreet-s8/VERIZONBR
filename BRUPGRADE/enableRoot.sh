source env.sh

for i in $gdsvzbinsnew1 $gdsvzbinsnew2 $gdsvzbrub6
do
echo -n "Enabling Root user on $i... "
ssh -q admin@$i 2> /dev/null << EOF
en
conf t
license install LK2-RESTRICTED_CMDS-88A4-FNLG-XCAU-U
no username root disable
username root password Gu@vuSgb5
username admin password Gu@vuSgb5
wr me
EOF
echo "Done"
done
