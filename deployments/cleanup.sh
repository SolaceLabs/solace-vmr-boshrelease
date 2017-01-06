#!/bin/bash

export SCRIPT=$(readlink -f "$0")
export SCRIPTPATH=$(dirname "$SCRIPT")

export LOG_FILE="cleanup.log"

source $SCRIPTPATH/common.sh

cd $SCRIPTPATH/..

echo "Logs in file $LOG_FILE"

deleteVMR $VM_JOB | tee $LOG_FILE
deleteOrphanedDisks | tee $LOG_FILE
cleanUpFolders | tee $LOG_FILE
