source env.sh

$SSH $gdsvzbinsnew1 "multipath -ll | grep 'HP,P2000'" | awk '{print $2}' | sed -e 's/(//g' -e 's/)//g' > $PWD/multipath
count=1
for i in `cat $PWD/multipath | head -4`
do
        for j in $gdsvzbinsnew1 $gdsvzbinsnew2
	do
		$SSH $j "/opt/tms/bin/cli -t 'en' 'conf t' 'mpio multipaths alias dbroot$count wwid $i' 'wr me'"
	done
	count=`expr $count + 1`
done
count=1
for i in `cat $PWD/multipath | tail -4`
do
        for j in $gdsvzbinsnew1 $gdsvzbinsnew2
        do
                $SSH $j "/opt/tms/bin/cli -t 'en' 'conf t' 'mpio multipaths alias backupdbroot$count wwid $i' 'wr me'"
        done
        count=`expr $count + 1`
done
echo "Restart Multipath on $gdsvzbnewins1"
$SSH ${gdsvzbinsnew1} "service multipathd restart"
echo "Restart Multipath on $gdsvzbnewins2"
$SSH ${gdsvzbinsnew2} "service multipathd restart"
