#!/bin/bash
# The purpose of this script is to set the VERSION environment variable to the version string a build
# should produce.
# The script is to be consumed by a build script by being sourced :
# source version.sh
# echo "I'm going to build version: $VERSION"
#
# The build script can also set the RELEASE_TYPE to one of these values before sourcing this script.
# RELEASE_TYPE have these effects :
#    When unset - This script produces a developer build version
#    When equals to "internal" - This script produces a developer build version
#    When equals to "patch" - This script produces a patch release
#    When equals to "minor" - This script produces a minor release
#    When equals to "major" - This script produces a major release


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
    echo "$major.$minor.$patch-$build_number+$USER.1" > userVersion
  fi

  next_dev_version=$(head -n 1 userVersion)

  regex="^([0-9]+)\.([0-9]+)\.([0-9]+)\-([0-9]+)\+.+\.([0-9]+)"
  if [[ $next_dev_version =~ $regex ]]
  then
    dev_build_number=${BASH_REMATCH[5]}
  else
    dev_build_number="1"
  fi

  echo "$major.$minor.$patch-$build_number+$USER.$((dev_build_number+1))" > userVersion
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
    RELEASE_TYPE="internal"
    VERSION="$major.$minor.$patch-$build_number+$USER.$dev_build_number"
  else
    case "$RELEASE_TYPE" in
      internal)
        bump_version_build
        VERSION="$major.$minor.$patch-$build_number"
        ;;
      patch)
        bump_version_patch
        VERSION="$major.$minor.$patch"
        ;;
      minor)
        bump_version_minor
        VERSION="$major.$minor.$patch"
        ;;
      major)
        bump_version_major
        VERSION="$major.$minor.$patch"
        ;;
      *)
        bump_version_build
        VERSION="$major.$minor.$patch-$build_number"
        ;;
    esac
  fi
}

