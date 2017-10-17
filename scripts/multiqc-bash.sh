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
## MultiQC
##
## Wrapper of MultiQC with many sanity check.
## MultiQC aggregates results from bioinformatics analyses across many
## samples into a single report.
##
## It searches a given directory for analysis logs and compiles a HTML
## report. It's a general use tool, perfect for summarising the output from
## numerous bioinformatics tools.
## 
## Inputs:
##      - String $INPUT: Input logs file(s).
##      - String $OUTPUT: report HTML file.
##      - String $PLAN: CSV file of sample plan.
##      - String $CONFIG: JSON configuration file.
##      - String $LOG: Log file.
## ---------------------------------------------------------------------------

# Import utils
path="${BASH_SOURCE[0]%/*}/"
. "${path}"utils-bash.sh

# Initiate variable of the wrapper ($INPUT, $OUTPUT, $PLAN, $CONFIG, $LOG)
init_wrapper $@

multiqc_outdir="${OUTPUT}"
multiqc_indir="${INPUT}"
create_directory ${LOG%/*}

# Catch variable in json
multiqc_path="$(get_json_entry ".multiqc.path" ${CONFIG})"
multiqc_option="$(get_json_entry ".multiqc.options" ${CONFIG})"
multiqc_threads="$(get_json_entry ".multiqc.threads" ${CONFIG})"
if [[ -n "${multiqc_path}" ]]; then
    multiqc_path="${multiqc_path%/}/"
fi

_fail=0 # variable to check if everything is ok

# Command line
cmd="${multiqc_path}multiqc ${multiqc_option} \
                            ${multiqc_indir} \
                            -o ${multiqc_outdir}"
$cmd > ${LOG} 2>&1 || _fail=1

exit ${_fail}
