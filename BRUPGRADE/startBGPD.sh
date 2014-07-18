source env.sh
source master_logic.sh

bgp_Quagga
echo -n "Starting Quagga on $gdsvzbcolvip ..." ; sleep 3
echo "Done"

$SSH $gdsvzbcolvip "ps -aef | grep bgpd | grep -v grep"
