#!/bin/bash

export SCRIPT=$(readlink -f "$0")
export SCRIPTPATH=$(dirname "$SCRIPT")

cd $SCRIPTPATH/..

./build.sh 

bosh upload release releases/solace-vmr/solace-vmr-0.4.0-1+vagrant.1.tgz 

bosh target 192.168.50.4 lite

bosh deployment deployments/solace-vmr-warden-medium-vmr-deployment.yml

echo "yes" | bosh deploy

bosh run errand  vmr-config-job

