#!/bin/bash

# package.sh: A simple wrapper for vagrant package command
# Copyright (C) © 🄯 2022 James Cuzella
# Copyright (C) © 🄯 2022 LyraPhase LLC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

box_filename=${1:-lyraphase-runner-macos-monterey-12-1-base.box}

# Tell Vagrantfile to avoid replacing SSH key & syncing Shared Folders
export VAGRANT_PACKAGE='true'
vagrant package --vagranfile Vagrantfile  --info info.json  --include README.md,LICENSE-macOSMonterey.pdf  --output "$box_filename"
