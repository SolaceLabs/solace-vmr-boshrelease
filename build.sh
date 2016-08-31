#!/bin/bash
FINAL_BUILD=""
SOLTR_LOAD="feature/7.2pcf2.0.12"

mkdir -p blobs/vmr_config_scripts
mkdir -p blobs/soltr_docker
tar czf blobs/vmr_config_scripts/vmr_config_scripts.tgz src/vmr_config_scripts/*

if [ ! -z $JENKINS_HOME ]
then
    FINAL_BUILD="--final"
    echo "Creating a final release"
else
    echo "Creating a development release"
fi

if [ -d /home/public/RND/loads ]; then
    cp -f `ls /home/public/RND/loads/solcbr/$SOLTR_LOAD/production/*evaluation-docker.tar.gz` blobs/soltr_docker/soltr-docker.tgz
else
    # Convenience for people working with bosh-lite.  Drop the latest container tar.gz in the host's vagrant folder and
    # the script will move it into the build's blobs.
    if [ -f /vagrant/*evaluation-docker.tar.gz ]; then
        mv -f `ls /vagrant/*evaluation-docker.tar.gz` blobs/soltr_docker/soltr-docker.tgz
    fi
fi

yes | bosh create release --name solace-vmr --force $FINAL_BUILD --with-tarball || exit 1

