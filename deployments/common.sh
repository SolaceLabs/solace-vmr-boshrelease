#!/bin/bash

export DEPLOYMENT_NAME=${DEPLOYMENT_NAME:-"solace-vmr-warden-deployment"}
export TEMPLATE_PREFIX=${TEMPLATE_PREFIX:-"solace-vmr-warden-deployment"}
export LOG_FILE=${LOG_FILE:-"runit.log"}

export SOLACE_DOCKER_BOSH_VERSION="29-solace-2"
export SOLACE_DOCKER_BOSH=${SOLACE_DOCKER_BOSH:-"/home/public/RND/loads/cloud-integration/docker-boshrelease/docker-${SOLACE_DOCKER_BOSH_VERSION}.tgz"}

export STEMCELL_VERSION="3312.7"
export STEMCELL_NAME="bosh-stemcell-$STEMCELL_VERSION-warden-boshlite-ubuntu-trusty-go_agent.tgz"
export STEMCELL_URL="https://s3.amazonaws.com/bosh-core-stemcells/warden/$STEMCELL_NAME"


function targetBosh() {

  bosh target 192.168.50.4 lite

}

function prepareBosh() {

  targetBosh

  FOUND_DOCKER_RELEASE=`bosh releases | grep "docker" | grep $SOLACE_DOCKER_BOSH_VERSION | wc -l`
  if [ "$FOUND_DOCKER_RELEASE" -eq "0" ]; then
     echo "Uploading docker bosh"
     bosh upload release $SOLACE_DOCKER_BOSH
  else
     echo "$SOLACE_DOCKER_BOSH was found $FOUND_DOCKER_RELEASE"
  fi

  echo "Uploading stemcell"

  if [ ! -f /tmp/$STEMCELL_NAME ]; then
      wget -O /tmp/$STEMCELL_NAME $STEMCELL_URL
  fi

  FOUND_STEMCELL=`bosh stemcells | grep bosh-warden-boshlite-ubuntu-trusty-go_agent | grep $STEMCELL_VERSION | wc -l`
  if [ "$FOUND_STEMCELL" -eq "0" ]; then
     bosh upload stemcell /tmp/$STEMCELL_NAME
  else
     echo "$STEMCELL_NAME was found $FOUND_STEMCELL"
  fi

}

function deleteOrphanedDisks() {

bosh disks --orphaned

ORPHANED_DISKS=`bosh disks --orphaned | grep -v "| Disk"  | grep "^|"  | awk -F\| '{ print $2 }'`

for DISK_ID in $ORPHANED_DISKS; do
	echo "Will delete $DISK_ID"
	bosh delete disk $DISK_ID
done

}

function deleteVMR() {

 VM_JOB=$1

 echo "Looking for VM job $VM_JOB" 
 VM_FOUND_COUNT=`bosh vms | grep $VM_JOB | wc -l`
 VM_RUNNING_FOUND_COUNT=`bosh vms | grep $VM_JOB | grep running |  wc -l`


 if [ "$VM_RUNNING_FOUND_COUNT" -eq "1" ]; then

   echo "Will stop monit jobs if any are running"
   bosh ssh $VM_JOB "sudo /var/vcap/bosh/bin/monit stop all" 

   RUNNING_COUNT=`bosh ssh $VM_JOB "sudo /var/vcap/bosh/bin/monit summary" | grep running | wc -l`
   MAX_WAIT=60
   while [ "$RUNNING_COUNT" -gt "0" ] && [ "$MAX_WAIT" -gt "0" ]; do
   	echo "Waiting for monit to finish shutdown - found $RUNNING_COUNT still running"
	sleep 5
        let MAX_WAIT=MAX_WAIT-5
        RUNNING_COUNT=`bosh ssh $VM_JOB "sudo /var/vcap/bosh/bin/monit summary " | grep running | wc -l`
   done

 fi

 if [ "$VM_FOUND_COUNT" -eq "1" ]; then

    # Delete the deployment 
    echo "yes" | bosh delete deployment $DEPLOYMENT_NAME
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



function prepareManifest() {

echo "Preparing a deployment manifest from template: $TEMPLATE_FILE "

if [ ! -f $TEMPLATE_FILE ]; then
 echo "Template file not found  $TEMPALTE_FILE"
 exit 1
fi

cp $TEMPLATE_FILE $MANIFEST_FILE

echo "Preparing manifest file $MANIFEST_FILE"

## Template keys to replace
## __VMR_JOB_NAME__
## __POOL_NAME__
## __SOLACE_DOCKER_IMAGE__

sed -i "s/__DEPLOYMENT_NAME__/$DEPLOYMENT_NAME/g" $MANIFEST_FILE
sed -i "s/__VMR_JOB_NAME__/$VMR_JOB_NAME/g" $MANIFEST_FILE
sed -i "s/__POOL_NAME__/$POOL_NAME/g" $MANIFEST_FILE
sed -i "s/__SOLACE_DOCKER_IMAGE__/$SOLACE_DOCKER_IMAGE/g" $MANIFEST_FILE

}

function build() {

echo "Will build the BOSH Release (May take some time)"

./build.sh > $LOG_FILE

if [ $? -ne 0 ]; then
 echo
 echo "Build failed."
 exit 1
fi 

}

function uploadAndDeployRelease() {

RELEASE_FILE=`ls releases/solace-vmr/solace-vmr-*.tgz | tail -1`

if [ -f $RELEASE_FILE ]; then

 targetBosh

 echo "Will upload release $RELEASE_FILE"

 bosh upload release $RELEASE_FILE >> $LOG_FILE

 bosh deployment $MANIFEST_FILE >> $LOG_FILE

 echo "Will deploy VMR with name $VMR_JOB_NAME , having POOL_NAME: $POOL_NAME, and using $SOLACE_DOCKER_IMAGE"

 echo "yes" | bosh deploy >> $LOG_FILE

else
 echo "Could not locate a release file in releases/solace-vmr/solace-vmr-*.tgz"
 exit 1
fi

}



###################### Common parameter processing ########################

if [ -z $1 ]; then
   export POOL_NAME=${POOL_NAME:-"Medium-VMR"}
else
   export POOL_NAME=$1
fi

if [ -z $2 ]; then
   export TEMPLATE_POSTFIX=""
else
   export TEMPLATE_POSTFIX=$2
fi

export VMR_JOB_NAME=${VMR_JOB_NAME:-$POOL_NAME}
export VM_JOB=${VM_JOB:-"$VMR_JOB_NAME/0"}

case $POOL_NAME in

  Medium-VMR)
	export SOLACE_DOCKER_IMAGE="latest-evaluation"
    ;;

  Large-VMR)
	export SOLACE_DOCKER_IMAGE="latest-evaluation"
    ;;

  Community-VMR)
	export SOLACE_DOCKER_IMAGE="latest-community"
    ;;

  *)
    echo
    echo "Sorry, I don't seem to know about POOL_NAME: $POOL_NAME"
    echo
    echo "Usage: $0 [Medium-VMR|Large-VMR|Community-VMR] [-cert]"
    echo 
    exit 1
    ;;
esac

export TEMPLATE_FILE="deployments/templates/${TEMPLATE_PREFIX}${TEMPLATE_POSTFIX}.yml.template"
export MANIFEST_FILE=${MANIFEST_FILE:-"manifest.yml"}

echo "$0 - Settings"
echo "    Deployment     $DEPLOYMENT_NAME"
echo "    VMR JOB NAME   $VMR_JOB_NAME"
echo "    VM             $VM_JOB"
