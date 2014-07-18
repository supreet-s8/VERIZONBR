#!/bin/bash

source env.sh
IPS="$PWD/IP.sh"
function getHosts()
{
  source ${IPS}
  if [[ $? -ne 0 ]]
  then
    printf "Unable to read source for IP Address List\nCannot continue"
    exit 255
  fi
}
# Get Hosts
getHosts
#------------------------------------------------------------------------
BACKUP="/data/Backup_Pre_Upgrade"
BINDINGS="$BACKUP/var/opt/tms/output/bindings"
FSLIST=''
UUIDLIST=''
MPATHLIST=''
WWIDLIST=''
WWID=''
MPATH=''
UUID=''
FS=''
ID=''
TEXT='storage.conf'

function restartMultipath 
{
for i in $ID; do
  #echo "Restarting Multipath Service on : $prefix$i"
  $SSH ${prefix}${i} "/sbin/service multipathd restart" >/dev/null
  sleep 15
done
}

function getFSLIST
{
for i in $ID; do
   FSLIST=''
   #echo "Retrieving configured File Systems."
   FSLIST=`$SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'show tps fs' | grep Filesystem" | awk '{print $2}'`
   if [[ $? -ne '0' ]]; then
      echo "Unable to determine configured Filesystem."
   fi
   if [[ ! $FSLIST || $FSLIST == "Filesystems" ]]; then
      echo "No Filesystem found configured at host $prefix$ID"
      FSLIST=''
   fi
done
}

function getUUID
{
for i in $ID; do
   UUID=''
   #echo "Retrieving UUID for FS $FS"
   UUID=`$SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'show tps fs'" | grep -A5 "Filesystem ${FS}" | grep UUID | awk '{print $2}'`
   if [[ $? -ne '0' ]]; then
      echo "Unable to determine UUID for FS ${FS}"
   fi
   if [[ ! $UUID ]]; then
      echo "No UUID found for FS $FS at host $prefix$ID"
   fi
done
}

function getMPATH 
{
for i in $ID; do
   MPATH=''
   #echo "Retrieving MPATH for FS $FS against UUID $UUID"
   MPATH=`$SSH ${prefix}${i} "/sbin/blkid | grep '${UUID}' | grep mpath" | awk '{print $1}' | cut -d'/' -f4 | sed -e 's/[p][0-9]*:$//'`
   if [[ $? -ne '0' ]]; then
      echo "Unable to determine device-name for FS ${FS}"
   fi
   if [[ ! $MPATH ]]; then
      echo "No device found for FS $FS with UUID $UUID at host $prefix$ID"
   fi
done
}

function getWWID
{
for i in $ID; do
   WWID=''
   #echo "Retrieving WWID for FS $FS."
   WWID=`$SSH ${prefix}${i} "grep '${MPATH} ' ${BINDINGS}" 2>/dev/null | awk '{print $2}'`
   if [[ $? -ne '0' ]]; then
      echo "Error : Unable to determine WWID for FS ${FS}"
   fi
   if [[ ! $WWID ]]; then
      echo "Error: WWID not found for FS $FS with UUID $UUID at host $prefix$ID"
   fi
done
}

function verifyBuild {
#clear
#echo "------- CHECKING BUILD VERSION -----------"
for i in $ID
do
  #echo -n "Version on ${prefix}${i}   "
  $SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'show ver'" | grep "Build ID" 
done
#read -p "Continue (y): "
#[[ "$REPLY" != "y" ]] && exit 0 
#clear
}

function verifyStorage {
#echo "------- Verifying Storage -----------"
for i in $ID
do
    #echo "Working on ${prefix}${i} ------------ "
    $SSH ${prefix}${i} "mount -o remount,rw /"
    $SSH ${prefix}${i} "> $BACKUP/$TEXT"
    $SSH ${prefix}${i} "/bin/df -h | grep mpath" >/dev/null
    if [[ $? -ne '0' ]]; then
      echo "Warning: Storage not mounted."
    else 
      echo "Storage mounted!"
    fi    
done
}

function configureWWID
{
for i in $ID; do
  #echo "Configuring WWID : $WWID" 
  $SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs $FS wwid $WWID' 'wr mem'"
  if [[ $? -ne '0' ]]; then echo "Unable to configure WWID for fs $FS"; fi
done
}

function enableTPSFS
{
for i in $ID; do
  #echo "Enable FS $FS at : $prefix$i"
  $SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'tps fs $FS enable' 'wr mem'"
  if [[ $? -ne '0' ]]; then echo "Unable to enable tps fs for $FS"; fi
done
}

function validateWWID
{
for i in $ID; do
  #echo "Validate WWID"
  $SSH ${prefix}${i} "/opt/tms/bin/cli -t 'en' 'conf t' 'show tps fs' | egrep 'Filesystem|WWID'"
  if [[ $? -ne '0' ]]; then echo "Unable to validate WWID for fs $FS"; else echo "----------- SUCCESS!"; fi
done
}

#################
ID=''
for ID in $dn ; do
   echo "WORKING ON NODE : $prefix$ID"
   FLAG=''
   #echo -n "----------- Checking BUILD version"
   echo "-------------------------------------"
   #verifyBuild
   echo -n "----------- Validating storage : "
   verifyStorage
   echo "----------- Get FS LIST"
   getFSLIST 
   if [[ $FSLIST ]]; then
    for FS in $FSLIST; do
     STR=''
     echo "----------- Identify UUID for FS \"$FS\""
     getUUID
     if [[ $UUID ]]; then
       echo "----------- Identify MPATH for UUID \"$UUID\""
       getMPATH 
       if [[ $MPATH ]]; then
         echo "----------- Identify WWID for MPATH \"$MPATH\""
         getWWID
         if [[ $WWID ]]; then
	   echo "----------- Writing WWID \"$WWID\" to $TEXT under backup."
           STR="${FS} ${UUID} ${MPATH} ${WWID}"
	   $SSH ${prefix}${ID} "echo ${STR} >> ${BACKUP}/${TEXT}"
	   if [[ $? -eq '0' ]]; then 
	     echo "-------------------------------------" 
	   else 
	     echo "----------- FAILED to write! Preserve the Run Log!" 
	     echo "-------------------------------------"
	   fi
           #echo "----------- Configure WWID \"$WWID\" for fs \"$FS\""
           #configureWWID
           #echo "----------- Enable TPS FS"
           #enableTPSFS
           FLAG=1
         else
           echo "Unable to locate WWID for FS \"$FS\" and MPATH \"$MPATH\" in $BINDINGS with UUID \"$UUID\""
	   echo "Skipping filesystem \"$FS\" ...!"
         fi
       else 
         echo "Unable to find device-name for FS $FS with UUID \"$UUID\""
         echo "Skipping filesystem \"$FS\" ...!"
       fi
     else 
       echo "Error: Unable to find UUID corresponding to FS \"$FS\""
       #echo "Restarting multipathd service, consider debugging storage issue manually..!" 
       echo "Skipping filesystem \"$FS\" ...!"
       FLAG=''
     fi
    done

   #if [[ $FLAG ]]; then
   # echo "----------- Restart Multipath"
   # restartMultipath
   # echo "----------- Validating storage"
   # verifyStorage
   # echo "----------- Validating WWID"
   # validateWWID
   # echo "------------------- DONE ----------------------"
   #fi
   else 
    echo "Error: No Filesystem Found Configured...!"
    echo "Skipping...!"
   fi
 echo ""
done

#ENABLE TPS FS FUNCTION#

