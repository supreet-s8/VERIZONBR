source env.sh

echo "Tables in rubixdb..."
$SSH ${gdsvzbinsnewvip} "psql -U postgres -d rubixdb -c \"\dt\" " 
echo " "
echo "Tables in rgedb..."
$SSH ${gdsvzbinsnewvip} "psql -U postgres -d rgedb -c \"\dt\" " 
