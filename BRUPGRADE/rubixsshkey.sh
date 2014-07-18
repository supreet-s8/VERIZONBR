source env.sh

for host in $gdsvzbrge1 $gdsvzbrge2
do
$PWD/sshkeytool --src $host --dest $gdsvzbrub1,$gdsvzbrub2,$gdsvzbrub3,$gdsvzbrub4,$gdsvzbrub5,$gdsvzbrub6,$gdsvzbrge1,$gdsvzbrge2
done
