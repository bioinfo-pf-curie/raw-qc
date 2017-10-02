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

## ---------------------------------------------------------------------
## Autotropos
##
## Wrapper of Autotropos with many sanity check. It creates FASTQ
## file(s) with adapters removed.
## Inputs:
##      - String $1: Input FASTQ file(s). (R1 (R2)?)
##      - String $2: Output FASTQ file(s). (R1 (R2)?)
##      - String $3: JSON configuration file.
## ---------------------------------------------------------------------

fastq=($1)
output=($2)
config=$3

# Import utils
path="${0%/*}/"
. "${path}"utils-bash.sh

# Catch variable in json
autotropos_path="$(get_json_entry ".autotropos.path" ${config})"
autotropos_option="$(get_json_entry ".autotropos.options" ${config})"
autotropos_threads="$(get_json_entry ".autotropos.threads" ${config})"

# Set some local variable
autotropos_input="-1 ${fastq[0]}"
autotropos_output="-o ${output[0]}"
if [[ ${#fastq[@]} -eq 2 && ${#output[@]} -eq 2 ]]; then
    autotropos_input+=" -2 ${fastq[1]}"
    autotropos_output+=" -p ${output[1]}"
fi
_fail=0 # variable to check if everything is ok 

# Command line:
cmd="${autotropos_path}autotropos ${autotropos_option} \
                                  --threads ${autotropos_threads} \
                                  ${autotropos_input} \
                                  ${autotropos_output}"

echo $cmd
$cmd || _fail=1

exit ${_fail}
