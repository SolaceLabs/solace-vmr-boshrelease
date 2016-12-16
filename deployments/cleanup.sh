#!/bin/bash

export SCRIPT=$(readlink -f "$0")
export SCRIPTPATH=$(dirname "$SCRIPT")

function deleteOrphanedDisks() {

bosh disks --orphaned

ORPHANED_DISKS=`bosh disks --orphaned | grep -v "| Disk"  | grep "^|"  | awk -F\| '{ print $2 }'`

for DISK_ID in $ORPHANED_DISKS; do
	echo "Will delete $DISK_ID"
	bosh delete disk $DISK_ID
done

}

function deleteVMR() {
 VMR_JOB=$1
 echo "Looking for VMR job $VMR_JOB" 
 VMR_FOUND_COUNT=`bosh vms | grep $VMR_JOB | wc -l`
 if [ "$VMR_FOUND_COUNT" -eq "1" ]; then

    bosh ssh $VMR_JOB "sudo monit stop all"

    # solace-vmr-warden-deployment
    echo "yes" | bosh delete deployment solace-vmr-warden-deployment
    # solace-vmr
    echo "yes" | bosh delete release solace-vmr
 else
    echo "No VMR job found"
 fi

}


function cleanUpFolders() {

echo "Removing build.sh produced files..."

REMOVE_LIST="/tmp/solace-messaging-blobs/ /tmp/bosh-blobs/"

rm -rf /tmp/solace-messaging-blobs/ /tmp/bosh-blobs/

( cd $SCRIPTPATH/..; rm -rf blobs/ .blobs/ releases/ .final_builds/ .dev_builds/ userVersion  )

}

# Need job name as $1
if [ -z $1 ]; then
   echo "Please provide a VMR job name, example: medium-vmr-job/0"
   exit 1
fi

deleteVMR $1
deleteOrphanedDisks
cleanUpFolders
