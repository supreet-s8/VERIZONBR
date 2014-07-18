source env.sh

echo "------- STOPPING HADOOP -----------"
echo "Go to master namenode and stop mapred and dfs manually --- write this in MOP and delete this line"
$PWD/datanodesUpgrade.sh
