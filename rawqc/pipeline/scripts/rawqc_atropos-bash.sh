#! /bin/bash

#- ---------------------------------------------------------------------------
#-    Copyright (C) 2017 - Institut Curie
#-
#- This file is a part of Raw-qc software.
#-
#- File author(s):
#-     Dimitri Desvillechabrol <dimitri.desvillechabrol@curie.fr>
#- 
#- Distributed under the terms of the CeCILL-B license.
#- The full license is in the LICENSE file, distributed with this
#- software.
#- ---------------------------------------------------------------------------

## ---------------------------------------------------------------------------
## Rawqc_atropos
##
## Wrapper of rawqc_atropos with many sanity check. It creates FASTQ
## file(s) without adapters.
## Inputs:
##      - String $INPUT: Input FastQ file(s).
##      - String $OUTPUT: Output FastQ file(s), metrics file and json file.
##      - String $CONFIG: JSON configuration file.
##      - String $LOG: Log file.
## ---------------------------------------------------------------------------

# Import utils
path="${BASH_SOURCE[0]%/*}/"
. "${path}"utils-bash.sh

# Initiate variable of the wrapper ($INPUT, $OUTPUT, $CONFIG, $LOG)
init_wrapper $@

# Catch variable in json
atropos_option="$(get_json_entry ".rawqc_atropos.options" ${CONFIG})"
atropos_threads="$(get_json_entry ".rawqc_atropos.threads" ${CONFIG})"

fastq_input=($INPUT)
# Add ID name in outputs and logs
outputs=(${OUTPUT})
create_directory ${outputs[0]%/*}
log_output=${LOG}
create_directory ${log_output%/*}

# set atropos prefix for logs and metrics
sub_index=$((${#outputs[@]} - 1))
atropos_prefix=${outputs[$sub_index]}

# Set some local variable
atropos_input=("-1" "${fastq_input[0]}")
atropos_output=("-o" "${outputs[0]}")
if [[ ${#fastq_input[@]} -eq 2 ]]; then
    atropos_input+=("-2" "${fastq_input[1]}")
    atropos_output+=("-p" "${outputs[1]}")
fi
_fail=0 # variable to check if everything is ok

# Command line:
cmd="rawqc_atropos ${atropos_option[@]} \
                   --threads ${atropos_threads} \
                   ${atropos_input[@]} \
                   ${atropos_output[@]} \
                   --logs ${atropos_prefix}.metrics \
                   --json ${atropos_prefix}"

echo $cmd > ${log_output}
$cmd >> "${log_output}" 2>&1 || _fail=1

exit ${_fail}
