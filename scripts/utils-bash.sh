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
#
create_directory(){
    if [ ! -d "${1}" ]; then
        mkdir "${1}"
    fi
}

# ----------------------------------------------------------------------
# Function to gets json entry and to remove leading and trailing quote.
# Inputs:
#       - String $1: Entry of JSON file like ".default.threads"
#       - String $2: JSON config file.
#
get_json_entry(){
    jq_output="$(jq "${1}" ${2})"
    echo $(sed -e 's/^"//' -e 's/"$//' <<<"${jq_output}")
}

# ----------------------------------------------------------------------
# 
#

# ----------------------------------------------------------------------
# Function to run bash as qsub or not.
# Inputs:
#       - String $1: Command line to run.
#       - String $2: JSON config file.
#       - Int $3: PID of a previous job.
#
run_bash(){
    local cmd=($1)
    local config=$2
    local pid=${3:-foo}
    if [[ -n ${CLUSTER} ]]; then
        echo OK       
    else 
        echo $(eval "bash ${cmd[@]} $config")
    fi
}
