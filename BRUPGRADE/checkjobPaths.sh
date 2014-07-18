source env.sh

flag=0
for i in `cat jobPaths`
do
$SSH $gdsvzbcolvip "$HADOOP dfs -ls $i 1> /dev/null 2> /dev/null"
x=`echo $?`
if [ $x -ne 0 ]
then 
echo "$i is missing "
flag=1
fi
done
if [ $flag -eq 0 ]
then
echo "All paths are present"
fi 
