#!/bin/bash

vagrant package --vagranfile Vagrantfile  --info info.json  --include README.md,LICENSE-macOSMonterey.pdf  --output lyraphase-runner-macos-monterey-12-1-base.box
