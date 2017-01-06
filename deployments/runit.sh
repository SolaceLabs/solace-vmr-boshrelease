#!/bin/bash

export SCRIPT=$(readlink -f "$0")
export SCRIPTPATH=$(dirname "$SCRIPT")

export LOG_FILE="runit.log"

source $SCRIPTPATH/common.sh

cd $SCRIPTPATH/..

prepareManifest

VM_FOUND_COUNT=`bosh vms | grep $VM_JOB | wc -l`

if [ "$VM_FOUND_COUNT" -eq "1" ]; then
   echo "bosh deployment is already done, the VM was found: $VM_JOB"
   echo
   echo "Will not build and will not DEPLOY"
   echo
   echo "You should cleanup the deployment with deployments/cleanup.sh ?!"
   echo
   exit 1
fi

echo "You can see build and deployment logs in $LOG_FILE"

echo "Checking to see if the vmr-agent has been built..."
ls ../vmr-agent/build/libs/vmr-agent-*.jar

if [ $? -ne 0 ]; then
   echo "No vmr-agent jar file found, will build it."
   cd ../vmr-agent
   ./gradlew assemble
   cd -
fi

build

prepareBosh

VM_FOUND_COUNT=`bosh vms | grep $VM_JOB | wc -l`

if [ "$VM_FOUND_COUNT" -eq "0" ]; then
   uploadAndDeployRelease
else
   echo "Skipping deployment as the VM was already found: $VM_JOB"
   echo "You should cleanup the deployment with deployments/cleanup.sh ?!"
fi

VM_FOUND_COUNT=`bosh vms | grep $VM_JOB | wc -l`
if [ "$VM_FOUND_COUNT" -eq "1" ]; then
   echo "bosh deployment is present, VM called $VM_JOB"
   echo "You can ssh to it:"
   echo "  bosh ssh $VM_JOB"
else
   echo "Could not find VM called $VM_JOB"
fi

