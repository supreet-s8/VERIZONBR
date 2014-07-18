source env.sh

for host in $gdsvzbinsnew1 $gdsvzbinsnew2 $gdsvzbins1 $gdsvzbins2
do
$PWD/sshkeytool --src $host --dest $gdsvzbinsnew1,$gdsvzbinsnew2,$gdsvzbins1,$gdsvzbins2
done
