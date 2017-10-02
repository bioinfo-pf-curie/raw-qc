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
## Fastqc
##
## Wrapper of Fastqc with many sanity check. It creates a HTML file
## with quality control of FASTQ file(s).
## Inputs:
##      - String $1: Fastq file(s).
##      - String $2: Output directory.
##      - String $3: JSON configuration file.
## ---------------------------------------------------------------------

fastq=($1)
output=$2
config=$3

# Import utils
path="${0%/*}/"
. "${path}"utils-bash.sh

# Catch variable in json
fastqc_path="$(get_json_entry ".fastqc.path" ${config})"
fastqc_option="$(get_json_entry ".fastqc.options" ${config})"
fastqc_threads="$(get_json_entry ".fastqc.threads" ${config})"

# Set some local variable
name=${fastq[0]%.fastq*}
create_directory $output
fastqc_zip_file="${output}${name}_fastqc.zip"

# if the zip file already exists we have nothing to do
test -d ${output} && test -f ${fastqc_zip_file} && test ${fastqc_zip_file} -nt ${fastq[0]} && exit 0

# if the file is empty, we don't need to do anything
test -s ${fastq[0]} || exit 0 

# seems that fastqc seldomly failed.
_fail=0
cmd="${fastqc_path}fastqc ${fastqc_opt} ${fastq[@]} \
                          --threads ${fastqc_threads} \
                          --outdir ${output}"
$cmd || _fail=1

# retry once in case of failure
test ${_fail} -eq 0 || { _fail=0; $cmd; } || _fail=1
test ${_fail} -eq 1 || test -d ${output} || _fail=1
test ${_fail} -eq 0 || rm -rf ${output} ${fastqc_zip_file}

exit ${_fail}
