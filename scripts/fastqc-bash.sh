#! /bin/bash

##############################################################################
#~ Fastqc
#~
#~ 

fastqc_path=${FASTQC_PATH}
name=${fq%.fastq}
fastqc_dir=${name}_fastqc
fastqc_zip_file=${fastqc_dir}.zip

# if the zip file already exists
# we have nothing to do
test -d ${fastqc_dir} && test -f ${fastqc_zip_file} && test ${fastqc_zip_file} -nt $fq && exit 0

# if the file is empty, we don't need to do anything
test -s $fq || exit 0 

# seems that fastqc seldomly failed.
_fail=0
cmd="fastqc --extract --nogroup --contaminants $fq"
$cmd || _fail=1

# retry once in case of failure
test ${_fail} -eq 0 || { _fail=0; $cmd; } || _fail=1
test ${_fail} -eq 1 || test -d ${fastqc_dir} || _fail=1
test ${_fail} -eq 0 || rm -rf ${fastqc_dir} ${fastqc_zip_file}

exit ${_fail}
