#!/bin/bash

RSYNCGREP=`ps -ef | grep "rsync -rtv" | grep -v "grep"`
username=root
LocalSyncfolder=/data/backup-hadoop-admin/
RemoteSyncfolder=/data/

remote=$1

#
# Check if rsync job already exists
#
if [ "$RSYNCGREP" != "" ];
then
echo "rsync already exists"
exit
fi

rsync -rtv $LocalSyncfolder $username@$remote:$RemoteSyncfolder
