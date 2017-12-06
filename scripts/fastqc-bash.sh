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
## Fastqc
##
## Wrapper of Fastqc with many sanity check. It creates a HTML file
## with quality control of FASTQ file(s).
## Inputs:
##      - String $INPUT: Input template.
##      - String $OUTPUT: Output directory.
##      - String $CONFIG: JSON configuration file.
##      - String $LOG: Log file.
## ---------------------------------------------------------------------------

# Import utils
path="${BASH_SOURCE[0]%/*}/"
. "${path}"utils-bash.sh

# Initiate variable of the wrapper ($INPUT, $OUTPUT, $CONFIG, $LOG)
init_wrapper $@

fastq=($INPUT)
outdir=$OUTPUT
log_output=$LOG
create_directory $outdir
create_directory ${log_output%/*}

# Catch variable in json
fastqc_path="$(get_json_entry ".fastqc.path" ${CONFIG})"
fastqc_opt="$(get_json_entry ".fastqc.options" ${CONFIG})"
fastqc_threads="$(get_json_entry ".fastqc.threads" ${CONFIG})"
if [[ -n "${fastqc_path}" ]]; then
    fastqc_path="${fastqc_path%/}/"
fi

# Set some local variable
name=$(basename ${fastq[0]%.fastq*})
fastqc_zip_file="${outdir}${name}_fastqc.zip"

# if the zip file already exists we have nothing to do
test -d ${outdir} && \
    test -f ${fastqc_zip_file} && \
    test ${fastqc_zip_file} -nt ${fastq[0]} && \
    exit 0

# if the file is empty, we don't need to do anything
test -s ${fastq[0]} || exit 0

# seems that fastqc rarely failed.
_fail=0
cmd="${fastqc_path}fastqc ${fastqc_opt} ${fastq[@]} \
                          --threads ${fastqc_threads} \
                          --outdir ${outdir}"
$cmd > ${log_output} 2>&1 || _fail=1

# retry once in case of failure
test ${_fail} -eq 0 || { _fail=0; $cmd > ${log_output} 2>&1; } || _fail=1
test ${_fail} -eq 1 || test -d ${outdir} || _fail=1
test ${_fail} -eq 0 || rm -rf ${outdir} ${fastqc_zip_file}

exit ${_fail}
