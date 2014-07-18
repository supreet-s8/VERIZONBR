source env.sh

$SSH $gdsvzbinsvip "$CLI -t en 'conf t' 'insta infinidb get-status-info'"
