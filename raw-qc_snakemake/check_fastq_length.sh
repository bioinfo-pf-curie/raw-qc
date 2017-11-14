#!/bin/bash

while getopts ":l:p:" optionName; do
case "$optionName" in

p) PROJECT="$OPTARG";;
l) LOG="$OPTARG";;
esac
done

echo "Project : $PROJECT"

for content in $PROJECT/*; do
    if [[ -d $content ]]; then
        for f in $content/*; do
            if [[ -f $f ]]; then
                line_number=$(zcat $f | wc -l)
                line_number=$(($line_number / 4))
                echo "Lines number of the file $f : $line_number" >> $LOG
                if [ $line_number -le 1000 ] && [[ $f = *".fastq.gz" ]]; then
                    echo "ERROR : PROJECT $PROJECT : the fastq file $f of the sample $content has a number of reads less or egal than the treshold at 1000. Please check in the samplesheet barcodes given" >> $LOG
                    exit 1
                else
                    echo "INFO : PROJECT $PROJECT : the fastq file $f of the sample $content has a number of reads more than the treshold at 1000" >> $LOG
                fi
            fi
        done
    fi
done
