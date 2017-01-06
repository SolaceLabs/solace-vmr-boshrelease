#!/bin/bash

export SCRIPT=$(readlink -f "$0")
export SCRIPTPATH=$(dirname "$SCRIPT")

export LOG_FILE="prepareBosh.log"

source $SCRIPTPATH/common.sh

cd $SCRIPTPATH/..

prepareBosh | tee $LOG_FILE
