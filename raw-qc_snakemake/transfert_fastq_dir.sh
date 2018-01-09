#!/bin/bash

## retrieve options

while getopts "s:i:r:o:p:l:" optionName; do
    case "${optionName}" in
        s) SAMPLE_SHEET="${OPTARG}";;
        i) INPUTDIR="${OPTARG}";;
        r) RUN_NAME="${OPTARG}";;
        o) OUTDIR="${OPTARG}";;
        p) PROJECT_NAME="${OPTARG}";;
        l) LOG="${OPTARG}";;
    esac
done

# check parameters values #
if [[ -z ${SAMPLE_SHEET} ]] || [[ -z ${INPUTDIR} ]] || [[ -z ${RUN_NAME} ]] || [[ -z ${OUTDIR} ]] || [[ -z ${PROJECT_NAME} ]] || [[ -z ${LOG} ]]; then
    echo "ERROR : There is one or many empty argument(s)"
    exit 1
fi

SAMPLES_LIST=${OUTDIR}/${RUN_NAME}.sampleList.txt

mkdir -p ${OUTDIR} &>>${LOG}


grep ${PROJECT_NAME} ${SAMPLE_SHEET}|awk -F"(,)" '{ print $1 }'|grep -v SampleID|sort -u > ${SAMPLES_LIST}

echo "SAMPLES_LIST: ${SAMPLES_LIST}" &>>${LOG}
if [[ ! -s ${SAMPLES_LIST} ]]
then
    echo "ERROR : the file '${SAMPLES_LIST}' is empty. The project '${PROJECT_NAME}' may be not present in the samplesheet file '${SAMPLE_SHEET}'." &>>${LOG}
    exit 1
fi

while read line
    do
        if [[ ! -z ${line} ]]; then
            SAMPLENAME="${RUN_NAME}${line}"
            echo "SAMPLENAME: ${SAMPLENAME}" &>>${LOG}
            mkdir -p ${OUTDIR}/${SAMPLENAME} &>>${LOG}
            R1_fastq_name=$(find ${INPUTDIR}/${line}/ -name "*_R1_*.fastq.gz")
            if [[ ! -z ${R1_fastq_name} ]] && [[ -f ${R1_fastq_name} ]]; then
                echo "R1_fastq_name: ${R1_fastq_name}" &>>${LOG}
                mkdir -p ${OUTDIR}/${SAMPLENAME}/ &>>${LOG}
                ln -s ${R1_fastq_name} ${OUTDIR}/${SAMPLENAME}/${RUN_NAME}${line}.R1.fastq.gz
            else
                echo "ERROR: there is no R1 fastq files in the directory '${INPUTDIR}/${line}/'" &>>${LOG}
            fi
            R2_fastq_name=$(find ${INPUTDIR}/${line}/ -name "*_R2_*.fastq.gz")
            if [[ ! -z ${R2_fastq_name} ]] && [[ -f ${R2_fastq_name} ]]; then
                echo "R2_fastq_name: ${R2_fastq_name}" &>>${LOG}
                mkdir -p ${OUTDIR}/${SAMPLENAME}/ &>>${LOG}
                ln -s ${R2_fastq_name} ${OUTDIR}/${SAMPLENAME}/${RUN_NAME}${line}.R2.fastq.gz
            fi
        fi
    done < ${SAMPLES_LIST}
