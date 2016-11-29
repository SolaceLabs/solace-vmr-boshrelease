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
        if [ ! -f blobs/soltr_docker/soltr-docker.tgz ]; then
            ruby ./buildUtils/imagePacker.rb `ls /vagrant/*evaluation-docker.tar.gz` `ls /vagrant/*community-docker.tar.gz` > blobs/soltr_docker/soltr-docker.tgz
        fi
    fi
fi

# 'bosh create release' creates a release artifact cache under ~/.bosh
# There does not appear to be any way to control where this directory is 
# located that I could find by looking at the code. As such we havve issues
# with the directory growing too large on
# our loadbuild machine. At the expense of slower builds we have decided
# to forgo caching. But since multiple builds can now share the same cache
# I will institure locking to ensure only build is active when the cache is
# being accessed via 'bosh create release'
#
LOCKFILE=$HOME/.bosh.lck
ARTIFACT_CACHE=$HOME/.bosh

exec 200>$LOCKFILE
echo "Waiting for global lock on release artifact cache: " `date`
flock -x 200
echo "Global lock for release artifact cache aquired: " `date`
rm -rf $ARTIFACT_CACHE

yes | bosh create release --dir . --name solace-vmr --force --final --version $VERSION --with-tarball || exit 1

rm -rf $ARTIFACT_CACHE
flock -u 200
