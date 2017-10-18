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

## Usage: raw-qc.sh [OPTIONS] -c <json> -1 <file> -o <dir>
##
## Raw-qc is a pipeline to check the quality of the input FastQ file(s).
##
## Required parameters:
##  -1, --read1 FILE1               The first read FastQ file (R1) or a single-
##                                  end read file.  [required if no --sample-plan]
##  -s, --sample-plan FILE          Sample plan with all sample to run in
##                                  parallele. [required if no --read1]
##  -c, --config-file JSON          The JSON config file of the pipeline.
##  -o, --output-dir OUTDIR         The directory where all the analysis are done
##
## Options:
##  -2, --read2 FILE2               The second read FastQ file (R2).
##  --cluster                       Run the pipeline with jobarray on a cluster
##                                  with Torque as scheduler.
##  -h, --help                      Show this message and exit.
##  -l, --license                   Show the license and exit.
##

# help and license
SOURCE="${BASH_SOURCE[0]}"
SRC_PATH="$(cd -P "$(dirname "$SOURCE")" && pwd)"
HELP=$(grep "^## " "${SOURCE}" | cut -c 4-)
LICENSE=$(grep "^#- " "${SOURCE}" | cut -c 4-)

if [[ ${#@} -lt 1 ]];then
    echo "${HELP}"
    exit 1
fi

# Transform long options to short ones
for arg in "$@"; do
  shift
  case "$arg" in
      "--read1") set -- "$@" "-1";;
      "--read2") set -- "$@" "-2";;
      "--prefix") set -- "$@" "-p";;
      "--output-dir") set -- "$@" "-o";;
      "--config-file") set -- "$@" "-c";;
      "--sample-plan") set -- "$@" "-s";;
      "--help") set -- "$@" "-h";;
      "--license") set -- "$@" "-l";;
      *) set -- "$@" "$arg" ;;
  esac
done

# Parse arguments
while getopts "1:2:p:o:c:s:hl-:" optchar; do
    case $optchar in
        -)
            case "${OPTARG}" in
                cluster)
                    CLUSTER="True"
                    ;;
                *)
                    echo "Invalid option: --${OPTARG}" >&2
                    echo "${HELP}"
                    exit 1
                    ;;
            esac;;
        1)
            READ1=$(realpath ${OPTARG})
            ;;
        2)
            READ2=$(realpath ${OPTARG})
            ;;
        p)
            PREFIX=${OPTARG}
            ;;
	    o)
            OUTDIR=$(realpath ${OPTARG})
            OUTDIR="${OUTDIR%/}/"
            ;;
	    c)
            CONFIG=$(realpath ${OPTARG})
            ;;
        s)
            PLAN=$(realpath ${OPTARG})
            ;;
	    h)
            echo "${HELP}"
            exit 1
            ;;
        l)
            echo "${LICENSE}"
            exit 1
            ;;
	    \?)
	        echo "Invalid option: -${OPTARG}" >&2
	        echo "${HELP}"
	        exit 1
	        ;;
	    :)
	        echo "Option -${OPTARG} requires an argument." >&2
	        echo "${HELP}"
	        exit 1
	        ;;
    esac
done

# Check if output directory and JSON config are provided
if [[ -z $OUTDIR && -z $CONFIG ]];then
    echo "${HELP}"
    exit 1
fi

# Set paths
SCRIPTS_PATH="${SRC_PATH%/}/scripts/"
CWD=$(pwd)
LOG_PATH="${OUTDIR}{{ID}}/logs/{{ID}}"

# Load utils function
. ${SCRIPTS_PATH}utils-bash.sh
create_directory "${OUTDIR}"

# Check if a sample plan or a FASTQ file is provided
if [[ -n $PLAN ]];then
    NB_SAMPLE=$(awk 'END{print NR}' $PLAN)
elif [[ -n $READ1 ]]; then
    # Create a temporary sample plan
    PLAN=$(create_sample_plan "${READ1} ${READ2}" "${PREFIX}")
    NB_SAMPLE=1
else
    echo "${HELP}"
    exit 1
fi

# Fastqc
raw_outdir="${OUTDIR}{{ID}}/fastqc_raw/{{ID}}"
cmd=$(
    get_command_line --tool "${SCRIPTS_PATH}fastqc-bash.sh" \
                     --plan ${PLAN} \
                     --input "__raw_data__" \
                     --output ${raw_outdir} \
                     --log-file "${LOG_PATH}.raw_fastqc.log"
)
pid_raw_fastqc=$(run_bash "${cmd}" ${CONFIG})

# Autotropos
autotropos_output=$(printf '%s %s' "${OUTDIR}{{ID}}/autotropos/{{ID}}_R1.fastq.gz" \
                                   "${OUTDIR}{{ID}}/autotropos/{{ID}}_R2.fastq.gz"
)
cmd=$(
    get_command_line --tool ${SCRIPTS_PATH}"autotropos-bash.sh" \
                     --plan ${PLAN} \
                     --input "__raw_data__" \
                     --output "${autotropos_output}" \
                     --log-file "${LOG_PATH}.autotropos.log"
)
pid_autotropos=$(run_bash "${cmd}" ${CONFIG})

# Fastqc
trim_outdir="${OUTDIR}{{ID}}/fastqc_trim/"
cmd=$(
    get_command_line --tool ${SCRIPTS_PATH}"fastqc-bash.sh" \
                     --plan ${PLAN} \
                     --input "${autotropos_output}" \
                     --output "${trim_outdir}" \
                     --log-file "${LOG_PATH}.trim_fastqc.log"
)
pid_trim_fastqc=$(run_bash "${cmd}" ${CONFIG} "${pid_autotropos}")

# MultiQC
multiqc_outdir="${OUTDIR}multiqc/"
cmd=$(
    get_command_line --tool ${SCRIPTS_PATH}"multiqc-bash.sh" \
                     --plan ${PLAN} \
                     --input "${OUTDIR}" \
                     --output "${multiqc_outdir}" \
                     --log-file "${OUTDIR}common_logs/multiqc.log"
)
pid_multiqc=$(run_bash "${cmd}" ${CONFIG} "${pid_trim_fastqc}")
