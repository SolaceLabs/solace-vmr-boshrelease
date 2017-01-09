#!/bin/bash

SCRIPT=`perl -e 'use Cwd "abs_path";print abs_path(shift)' $0`
export SCRIPTPATH=$(dirname "$SCRIPT")

export LOG_FILE="prepareBosh.log"

source $SCRIPTPATH/common.sh

cd $SCRIPTPATH/..

prepareBosh | tee $LOG_FILE
