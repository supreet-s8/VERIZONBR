source env.sh

for i in $gdsvzbrub1 $gdsvzbrub2 $gdsvzbrub3 $gdsvzbrub4 $gdsvzbrub5 
do
echo -n "Starting Tomact on $i... "
$SSH $i "/data/apache-tomcat/apache-tomcat-7.0.27/bin/startup.sh"
echo "Done"
done

echo -n "Starting Tomcat on $gdsvzbrge1... "
$SSH $gdsvzbrge1 "/data/apache-tomcat/apache-tomcat-7.0.27_as701/bin/startup.sh"
echo "Done"
