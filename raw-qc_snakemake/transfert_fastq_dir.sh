#!/bin/bash

## RECUP OPTIONS

while getopts "s:i:r:o:p:" optionName; do
case "$optionName" in

s) SAMPLE_SHEET="$OPTARG";;
i) INPUTDIR="$OPTARG";;
r) RUN_NAME="$OPTARG";;
o) OUTDIR="$OPTARG";;
p) PROJECT_NAME="$OPTARG";;

esac
done

SAMPLES_LIST=$OUTDIR/$RUN_NAME.sampleList.txt

mkdir -p $OUTDIR


grep $PROJECT_NAME $SAMPLE_SHEET|awk -F"(,)" '{ print $1 }'|grep -v SampleID|sort -u > $SAMPLES_LIST

if [[ ! -s $SAMPLES_LIST ]]
then
    echo "ERROR : the file '$SAMPLES_LIST' is empty. The project '$PROJECT_NAME' may be not present in the samplesheet file '$SAMPLE_SHEET'."
    exit 1
fi

while read line
    do
        if [[ $line != "" ]]; then

            SAMPLENAME="${RUN_NAME}${line}"

            #echo $SAMPLENAME

            mkdir -p $OUTDIR/$SAMPLENAME

            ln -s $INPUTDIR/$line/* $OUTDIR/$SAMPLENAME/
        fi

    done < $SAMPLES_LIST
