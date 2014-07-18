source env.sh

for host in $gdsvzbrub1 $gdsvzbrub2 $gdsvzbrub3 $gdsvzbrub4 $gdsvzbrub5 $gdsvzbrub6 $gdsvzbrge1 $gdsvzbrge2
do
scp -qr $PWD/PrefetchAnalyzer root@$host:/data/
done
$SSH $gdsvzbrubvip "/usr/bin/python /data/PrefetchAnalyzer/PrefetchAnalyzer.py -f /data/instances/br_rubix/0/bin/rubix.log -c 2"
