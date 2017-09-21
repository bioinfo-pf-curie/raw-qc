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

## ----------------------------------------------------------------------
## Fastqc
##
## Wrapper of Fastqc with many sanity check.
## Inputs:
##      - String $1: Fastq file(s).
##      - String $2: Output directory.
## ---------------------------------------------------------------------

fastq=($1)
output=$2

# Catch variable in json
fastqc_path="$(jq ".fastqc.path" ${CONFIG})"
fastqc_option="$(jq ".fastqc.options" ${CONFIG})"
fastqc_threads="$(jq ".fastqc.threads" ${CONFIG})"

# Set some local variable
name=${fastq[0]%.fastq*}
fastqc_dir="${output}/fastqc/"
create_directory $fastqc_dir
fastqc_zip_file="${fastqc_dir}${name}_fastqc.zip"

# if the zip file already exists
# we have nothing to do
test -d ${fastqc_dir} && test -f ${fastqc_zip_file} && test ${fastqc_zip_file} -nt ${fastq[0]} && exit 0

# if the file is empty, we don't need to do anything
test -s $fq || exit 0 

# seems that fastqc seldomly failed.
_fail=0
cmd="${FASTQC_PATH}fastqc ${FASTQC_OPT} ${fastq[@]} --threads ${fastqc_threads} --outdir ${fastqc_dir}"
$cmd || _fail=1

# retry once in case of failure
test ${_fail} -eq 0 || { _fail=0; $cmd; } || _fail=1
test ${_fail} -eq 1 || test -d ${fastqc_dir} || _fail=1
test ${_fail} -eq 0 || rm -rf ${fastqc_dir} ${fastqc_zip_file}

exit ${_fail}
