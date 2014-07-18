source env.sh

$SSH root@${gdsvzbcol1} "mkdir /data/scripts/"
scp -q $PWD/bkp-admin-sync.sh root@${gdsvzbcol1}:/data/scripts/
$SSH root@${gdsvzbcol1} "/data/scripts/bkp-admin-sync.sh $gdsvzbcol2"
