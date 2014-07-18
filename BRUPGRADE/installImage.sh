#!/bin/bash

source env.sh

function xferimg {

for i in $gdsvzbcol1 $gdsvzbcol2 $gdsvzbcmp1 $gdsvzbcmp2 $gdsvzbcmp3 $gdsvzbcmp4 $gdsvzbcmp5 $gdsvzbcmp6 $gdsvzbcmp7 $gdsvzbcmp8 $gdsvzbcmp9 $gdsvzbcmp10 $gdsvzbcmp11 $gdsvzbcmp12 $gdsvzbcmp13  $gdsvzbrge1 $gdsvzbrge2 $gdsvzbrub1 $gdsvzbrub2 $gdsvzbrub3 $gdsvzbrub4 $gdsvzbrub5
do 
  echo "Transferring image to $i"
  $SSH $i 'mount -o remount,rw /'
  $SSH $i '/bin/rm -rf /var/opt/tms/images/*'
  scp -q $PWD/image-bizreflex3.4.rc2.img root@$i:/var/opt/tms/images/
done

}


function installImage { 

for i in $gdsvzbcol1 $gdsvzbcol2 $gdsvzbcmp1 $gdsvzbcmp2 $gdsvzbcmp3 $gdsvzbcmp4 $gdsvzbcmp5 $gdsvzbcmp6 $gdsvzbcmp7 $gdsvzbcmp8 $gdsvzbcmp9 $gdsvzbcmp10 $gdsvzbcmp11 $gdsvzbcmp12 $gdsvzbcmp13  $gdsvzbrge1 $gdsvzbrge2 $gdsvzbrub1 $gdsvzbrub2 $gdsvzbrub3 $gdsvzbrub4 $gdsvzbrub5
do 
  echo "Initiating install on $i"
  $SSH $i "/opt/tms/bin/cli -t 'en' 'conf term' 'wr mem' 'image install image-bizreflex3.4.rc2.img  progress no-track verify ignore-sig' " &
done

}

function verifyProgress {

remaining="0"
for i in $gdsvzbcol1 $gdsvzbcol2 $gdsvzbcmp1 $gdsvzbcmp2 $gdsvzbcmp3 $gdsvzbcmp4 $gdsvzbcmp5 $gdsvzbcmp6 $gdsvzbcmp7 $gdsvzbcmp8 $gdsvzbcmp9 $gdsvzbcmp10 $gdsvzbcmp11 $gdsvzbcmp12 $gdsvzbcmp13  $gdsvzbrge1 $gdsvzbrge2 $gdsvzbrub1 $gdsvzbrub2 $gdsvzbrub3 $gdsvzbrub4 $gdsvzbrub5
do
  echo -n "Checking progress on ${i}......"
  $SSH ${i} "/opt/tms/bin/cli -t 'en' 'conf term' 'show images' " | grep "Image install in progress" 
  if [[ $? -ne 0 ]]
  then 
    echo "Install Complete..."
  else
    remaining="1"
  fi
done
if [[ ${remaining} -eq "0" ]]
then
  echo "All nodes completed image install" ; 
fi

}

xferimg
installImage
while true
do
  clear
  verifyProgress
  echo
  echo " THIS SCREEN WILL AUTO REFRESH EVERY 30s"
  echo "Hit CTRL+C to break, Once all the images are completely installed"
  sleep 30
done

