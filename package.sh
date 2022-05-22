#!/bin/bash

box_filename=${1:-lyraphase-runner-macos-monterey-12-1-base.box}

# Tell Vagrantfile to avoid replacing SSH key & syncing Shared Folders
export VAGRANT_PACKAGE='true'
vagrant package --vagranfile Vagrantfile  --info info.json  --include README.md,LICENSE-macOSMonterey.pdf  --output "$box_filename"
