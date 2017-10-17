#! /bin/bash

#- ---------------------------------------------------------------------------
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
#- ---------------------------------------------------------------------------

## ---------------------------------------------------------------------------
## Autotropos
##
## Wrapper of Autotropos with many sanity check. It creates FASTQ
## file(s) with adapters removed.
## Inputs:
##      - String $INPUT: Input FASTQ file(s). (R1 (R2)?)
##      - String $OUTPUT: Output FASTQ file(s). (R1 (R2)?)
##      - String $PLAN: CSV file of sample plan.
##      - String $CONFIG: JSON configuration file.
##      - String $LOG: Log file.
## ---------------------------------------------------------------------------

# Import utils
path="${BASH_SOURCE[0]%/*}/"
. "${path}"utils-bash.sh

# Initiate variable of the wrapper ($INPUT, $OUTPUT, $PLAN, $CONFIG, $LOG)
init_wrapper $@

# Check if task is launch as job array
if [[ -n ${PBS_ARRAYID} ]]; then
    sample_array=($(get_sample $PLAN ${PBS_ARRAYID}))
else
    # case of one sample
    sample_array=($(get_sample $PLAN 1))
fi

fastq_input=("${sample_array[@]:1:2}")
# Add ID name in outputs and logs
fastq_output=($(populate_template "${OUTPUT}" ${sample_array[0]}))
log_output=$(populate_template "${LOG}" ${sample_array[0]})
create_directory ${log_output%/*}

# Catch variable in json
autotropos_path="$(get_json_entry ".autotropos.path" ${CONFIG})"
autotropos_option="$(get_json_entry ".autotropos.options" ${CONFIG})"
autotropos_threads="$(get_json_entry ".autotropos.threads" ${CONFIG})"
if [[ -n "${autotropos_path}" ]]; then
    autotropos_path="${autotropos_path%/}/"
fi

# Set some local variable
autotropos_input=("-1" "${fastq_input[0]}")
autotropos_output=("-o" "${fastq_output[0]}")
if [[ ${#fastq_input[@]} -eq 2 && ${#fastq_output[@]} -eq 2 ]]; then
    autotropos_input+=("-2" "${fastq_input[1]}")
    autotropos_output+=("-p" "${fastq_output[1]}")
fi
_fail=0 # variable to check if everything is ok 

# Command line:
cmd="${autotropos_path}autotropos ${autotropos_option[@]} \
                                  --threads ${autotropos_threads} \
                                  ${autotropos_input[@]} \
                                  ${autotropos_output[@]}"
$cmd > "${log_output}" 2>&1 || _fail=1

exit ${_fail}
