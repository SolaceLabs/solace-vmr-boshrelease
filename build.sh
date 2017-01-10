#!/bin/bash

source buildUtils/version.sh
set_version

echo "Creating $RELEASE_TYPE release : $VERSION"
yes | bosh create release --dir . --name solace-vmr --force --final --version $VERSION --with-tarball || exit 1

