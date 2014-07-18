#!/bin/bash
# 
# Copyright 2014 Guavus Network Systems Ltd.
#
# Support functions for Deployment
#
# 
# Revision History
# ~~~~~~~~~~~~~~~~
# 10-06-2014	Kiran Subash	Initial Aggregation of all functions into single library
#
#


function ssh_init
{
  if [[ ! -e /home/`whoami`/.ssh/id_rsa.pub ]] 
  then
    echo "No existing ssh key pair found, generating new...."
    /usr/bin/ssh-keygen -f /home/`whoami`/.ssh/id_rsa -q 
  fi
}

function share_sshkey
{
  echo "Copying your SSH Key to remote host $1"
  ssh_init
  cat /home/`whoami`/.ssh/id_rsa.pub | ssh -l root $1 "umask 077 ; test -d .ssh || mkdir .ssh ; cat >> .ssh/authorized_keys2"
}

function share_sshkey_TM
{
  echo "Copying your SSH Key to remote TM Appliance $1"
  ssh_init
  KEY=`cat ~/.ssh/id_rsa.pub`
  echo -n "/opt/tms/bin/cli -t 'en' 'configure terminal' 'ssh client user admin authorized-key sshv2 \"${KEY}\"' " > sshcmdfile
  /usr/bin/ssh -l root $1 $(<sshcmdfile)
}

function xfer_install_image
{
  imagepath=$1
  host=$2
  if [[ -r ${imagepath} ]]
  then
    scp ${imagepath} root@$host:/tmp/
  else
    echo "Image: ${imagepath} not found"
  fi
}

function fetch_image
{
  image_url=$1
  host=$2
  image=`basename ${image_url}`
  $SSH ${host} "/opt/tms/bin/cli -t 'en' 'conf terminal' 'image fetch ${image_url}' "
  $SSH ${host} "/opt/tms/bin/cli -t 'en' 'conf terminal' 'show images'" | grep -q ${image} && echo "Image $image copied succesfully" || echo "Image $image not copied succesfully"
}

function sync_hwclock 
{
  echo "Syncing Hardware Clock on $1"
  $SSH $1 "mount -o remount,rw / && [[ -L /dev/rtc ]] || ln -s /dev/rtc0 /dev/rtc"
  $SSH $1 "hwclock --systohc && hwclock --show"
  if [[ $? -ne 0 ]]
  then
    printf "Unable to setup HW clock on $1\n"
  fi
}

function install_image
{
  image=$1
  host=$2
  $SSH ${host} "/opt/tms/bin/cli -t 'en' 'conf terminal' 'show images'" | grep -q ${image} && available=1 || available=0
  if [[ ${available} -eq 1 ]]
  then
    $SSH ${host} "/opt/tms/bin/cli -t 'en' 'conf terminal' 'image install ${image} location 2 progress no-track verify ignore-sig' " &
    echo "Image ${image} install under progress on host ${host}" 
  else 
    echo "Image: ${image} not available on ${host}"
  fi
}

function verifyProgress 
{
  remaining="0"
  for host ; do
    echo -n "Checking progress on ${host}......"
    $SSH ${host} "/opt/tms/bin/cli -t 'en' 'conf term' 'show images' " | grep "Image install in progress"
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
