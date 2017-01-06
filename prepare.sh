#!/bin/bash

cp -f config/private.yml.example config/private.yml

ls vmr_images/*tar.gz > /dev/null 2>&1

if [ $? -ne 0 ]; then
   echo "Could not locate any Solace VMR Docker images.  Did you place the images provided by Solace in the vmr_images directory?"
   exit 1
fi

ls vmr_images/*tar.gz | xargs ruby ./buildUtils/imagePacker.rb > vmr_images/solace-vmr-images.tgz
if [ $? -ne 0 ]; then
   echo "Could not pack the Solace VMR Docker images into a single tarball."
   exit 1
fi

bosh add blob vmr_images/solace-vmr-images.tgz vmr_image