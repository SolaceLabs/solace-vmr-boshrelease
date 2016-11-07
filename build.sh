#!/bin/bash

source ../solace-versioning/version.sh
set_version

mkdir -p blobs/vmr_config_scripts
mkdir -p blobs/soltr_docker
tar czf blobs/vmr_config_scripts/vmr_config_scripts.tgz src/vmr_config_scripts/*

if [ -d /home/public/RND/loads ]; then
    ruby ./buildUtils/imagePacker.rb `ls /home/public/RND/loads/solcbr/$SOLTR_LOAD/production/*evaluation-docker.tar.gz` `ls /home/public/RND/loads/solcbr/$SOLTR_LOAD/production/*community-docker.tar.gz` > blobs/soltr_docker/soltr-docker.tgz
else
    # Convenience for people working with bosh-lite.  Drop the latest container tar.gz in the host's vagrant folder and
    # the script will move it into the build's blobs.
    if [ -f /vagrant/*evaluation-docker.tar.gz ]; then
        ruby ./buildUtils/imagePacker.rb `ls /vagrant/*evaluation-docker.tar.gz` `ls /vagrant/*community-docker.tar.gz` blobs/soltr_docker/soltr-docker.tgz
    fi
fi

yes | bosh create release --name solace-vmr --force --final --version $VERSION --with-tarball || exit 1

