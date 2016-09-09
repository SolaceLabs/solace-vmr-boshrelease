#!/bin/bash
SOLTR_LOAD="feature/7.2pcf2.0.12"

function parse_version()
{
  regex="^([0-9]+)\.([0-9]+)\.([0-9]+)\-([0-9]+)(.*)?"

  next_version=$(head -n 1 version)
  if [[ $next_version =~ $regex ]]
  then
    major=${BASH_REMATCH[1]}
    minor=${BASH_REMATCH[2]}
    patch=${BASH_REMATCH[3]}
    build_number=${BASH_REMATCH[4]}
  else
    echo "This version was invalid: $next_version"
    exit 1
  fi
}

function bump_version_dev()
{
  if [ ! -f userVersion ]
  then
    echo "$major.$minor.$patch-$build_number+dev.$USER.1" > userVersion
  fi

  next_dev_version=$(head -n 1 userVersion)

  regex=".+?\.$USER\.([0-9]+)"
  if [[ $next_dev_version =~ $regex ]]
  then
    dev_build_number=${BASH_REMATCH[1]}
  else
    dev_build_number="1"
  fi

  echo "$major.$minor.$patch-$build_number+dev.$USER.$((dev_build_number+1))" > userVersion
}

function bump_version_build()
{
  echo "$major.$minor.$patch-$((build_number+1))" > version
}

function bump_version_patch()
{
  echo "$major.$minor.$((patch+1))-1" > version
}

function bump_version_minor()
{
  echo "$major.$((minor+1)).0-1" > version
}

function bump_version_major()
{
  echo "$((major+1)).0.0-1" > version
}

function set_version()
{
  parse_version

  if [ -z "$RELEASE_TYPE" ]
  then
    bump_version_dev
    BOSH_RELEASE_VERSION="$major.$minor.$patch-$build_number+dev.$USER.$dev_build_number"
    echo "Creating a development release: $BOSH_RELEASE_VERSION"
  else
    case "$RELEASE_TYPE" in
      internal)
        bump_version_build
        BOSH_RELEASE_VERSION="$major.$minor.$patch-$build_number"
        ;;
      patch)
        bump_version_patch
        BOSH_RELEASE_VERSION="$major.$minor.$patch"
        ;;
      minor)
        bump_version_minor
        BOSH_RELEASE_VERSION="$major.$minor.$patch"
        ;;
      major)
        bump_version_major
        BOSH_RELEASE_VERSION="$major.$minor.$patch"
        ;;
      *)
        bump_version_build
        BOSH_RELEASE_VERSION="$major.$minor.$patch-$build_number"
        ;;
    esac

    echo "Creating a final release: $BOSH_RELEASE_VERSION"
  fi
}

set_version

mkdir -p blobs/vmr_config_scripts
mkdir -p blobs/soltr_docker
tar czf blobs/vmr_config_scripts/vmr_config_scripts.tgz src/vmr_config_scripts/*

if [ -d /home/public/RND/loads ]; then
    cp -f `ls /home/public/RND/loads/solcbr/$SOLTR_LOAD/production/*evaluation-docker.tar.gz` blobs/soltr_docker/soltr-docker.tgz
else
    # Convenience for people working with bosh-lite.  Drop the latest container tar.gz in the host's vagrant folder and
    # the script will move it into the build's blobs.
    if [ -f /vagrant/*evaluation-docker.tar.gz ]; then
        mv -f `ls /vagrant/*evaluation-docker.tar.gz` blobs/soltr_docker/soltr-docker.tgz
    fi
fi

yes | bosh create release --name solace-vmr --force --final --version $BOSH_RELEASE_VERSION --with-tarball || exit 1

