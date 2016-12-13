#!/bin/bash

source ../solace-versioning/version.sh
set_version

### Prepare BLOB store ###

mkdir -p blobs/vmr_config_scripts
tar czf blobs/vmr_config_scripts/vmr_config_scripts.tgz src/vmr_config_scripts/*

mkdir -p blobs/soltr_docker
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

#if [ ! -d blobs/java ]; then
#  mkdir -p blobs/java
#  JDK_URL="https://download.run.pivotal.io/openjdk-jdk/trusty/x86_64/openjdk-1.8.0_111.tar.gz"
#  JDK_FILE="blobs/java/openjdk-jdk-trusty-1.8.0_111.tar.gz"
#  wget -O $JDK_FILE $JDK_URL
#  JRE_URL="https://download.run.pivotal.io/openjdk/trusty/x86_64/openjdk-1.8.0_111.tar.gz"
#  JRE_FILE="blobs/java/openjdk-jre-trusty-1.8.0_111.tar.gz"
#  wget -O $JRE_FILE $JRE_URL
#fi

mkdir -p blobs/vmr_agent
VMR_AGENT_SOURCE_FILE=${VMR_AGENT_SOURCE_FILE:-`ls ../vmr-agent/build/libs/vmr-agent-*.jar`}
VMR_AGENT_TARGET_FILE=blobs/vmr_agent/vmr-agent.jar

if [ ! -f $VMR_AGENT_SOURCE_FILE ]; then
   echo "Could not locate a VMR-Agent jar file, was the vmr-agent project built?"
   exit 1
else
   echo "Copying $VMR_AGENT_SOURCE_FILE to $VMR_AGENT_TARGET_FILE"
   cp $VMR_AGENT_SOURCE_FILE $VMR_AGENT_TARGET_FILE
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
