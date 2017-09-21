#! /bin/bash

#- ---------------------------------------------------------------------
#-    Copyright (C) 2017 - Institut Curie
#-
#- This file is a part of Raw-qc software.
#-
#- File author(s):
#-     Dimitri Desvillechabrol <dimitri.desvillechabrol@curie.fr>
#- 
#- Distributed under the terms of the 3-clause BSD license.
#- The full license is in the LICENSE file, distributed with this
#- software.
#- ---------------------------------------------------------------------

# ----------------------------------------------------------------------
# Check if a directory already exist and create the directory if it does
# not exit.
# Inputs:
#       - String $1: Directory to create.
create_directory()
{
    if [ ! -d "${1}" ]; then
        mkdir "${1}"
    fi
}
