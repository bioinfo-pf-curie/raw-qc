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

## Usage: raw-qc.sh

HELP=$(grep "^## " "${BASH_SOURCE[0]}" | cut -c 4-)
LICENSE=$(grep "^#- " "${BASH_SOURCE[0]}" | cut -c 4-)

# Parse parameters
while [[ $# > 0 ]]
do
    key="$1"

    case $key in
        -h|--help)
            echo "${HELP}"
            exit 1
            ;;
        -l|--license)
            echo "${LICENSE}"
            exit 1
            ;;
        -1|--read1)
            READ1=$2
            shift
            ;;
        -2|--read2)
            READ2=$2
            shift
            ;;
        -o|--output-dir)
            OUTDIR="${2%/}/"
            shift
            ;;
        -c|--config-file)
            CONFIG=$2
            shift
            ;;
        --cluster)
            CLUSTER=$2
            shiftat
            ;;
        *)
            # unknown option
            ;;
    esac
    shift
done

# Set paths
BIN_PATH=$(realpath $0)
BIN_PATH="${BIN_PATH%/*}/"
SCRIPTS_PATH="${BIN_PATH%/*}/scripts/"

# Set global variable
PREFIX=${READ1%[_.]R[12][_.]*}

# Load utils function
. ${SCRIPTS_PATH}utils-bash.sh
create_directory "${OUTDIR}"

# Fastqc
echo "Run raw fastqc..."
raw_outdir="${OUTDIR}fastqc_raw"
cmd=${SCRIPTS_PATH}'fastqc-bash.sh "'${READ1}' '${READ2}'" '${raw_outdir}
run_bash "${cmd}" ${CONFIG}

# Autotropos
echo "Run Autotropos..."
TRIM1="${OUTDIR}autotropos/${PREFIX}_R1.fastq.gz"
TRIM2="${OUTDIR}autotropos/${PREFIX}_R2.fastq.gz"
cmd=${SCRIPTS_PATH}'autotropos-bash.sh "'${READ1}' '${READ2}'" "'${TRIM1}' '${TRIM2}'"'
run_bash "${cmd}" ${CONFIG}

# Fastqc
echo "Run trimmed fastqc..."
trim_outdir="${OUTDIR}fastqc_trim"
cmd=${SCRIPTS_PATH}'fastqc-bash.sh "'${TRIM1}' '${TRIM2}'" '${trim_outdir}
run_bash "${cmd}" ${CONFIG}
