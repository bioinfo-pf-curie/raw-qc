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

# ----------------------------------------------------------------------------
# Check if a directory already exist and create the directory if it does not
# exist.
# Inputs:
#       - String $1: Directory to create.
#
create_directory(){
    if [ ! -d "${1}" ]; then
        mkdir -p "${1}"
    fi
}

# ----------------------------------------------------------------------------
# Create a temporary sample plan if only one sample is provided.
# Inputs:
#       - String $1: FASTQ file(s).
#       - String $2: ID of the sample.
#
create_sample_plan(){
    local fastq=($1)
    local prefix=${2:-None}
    if [[ "${prefix}" == "None" ]]; then
        prefix=${fastq[0]##*/}
        prefix=${prefix%[_.]R[12][_.]*}
    fi
    echo "${prefix},,${fastq[0]},${fastq[1]}" > "${OUTDIR}TMP_SAMPLE_PLAN"
    echo "${OUTDIR}TMP_SAMPLE_PLAN"
}

# ----------------------------------------------------------------------------
# Get a sample from a sample plan with an indice. Return an array with the
# corresponding ID and FASTQ file(s).
# Inputs:
#       - String $1: Sample plan file.
#       - Int $2: Number of the sample in sample plan file.
#
get_sample(){
    local plan=$1
    local indice=$2
    local s=($( awk -F "," -v i=${indice} 'NR==i{print $1" "$3" "$4}' ${plan}))
    if [[ "${s[2]}" == "NA" ]];then
        echo "${s[@]:0:2}"
    else
        echo "${s[@]}"
    fi
}

# ----------------------------------------------------------------------------
# Create the string command line for a tool.
# Inputs:
#       - String --tool: Complete path of the using tool.
#       - String --plan: Sample plan file.
#       - String --input: Template name or "__raw_dat__" key world.
#       - String --output: Template name.
#
# Template name(s) is like:
#       "{{ID}}/fastqc/{{ID}}"
#
get_command_line(){
    while [[ $# > 0 ]]; do
        key="$1"
        case "${key}" in
            -t|--tool)
                local t="$2"
                shift
                ;;
            -p|--plan)
                local p="$2"
                shift
                ;;
            -i|--input)
                local i="$2"
                shift
                ;;
            -o|--output)
                local o="$2"
                shift
                ;;
            -l|--log-file)
                local l="$2"
                shift
                ;;
            *)
                ;;
        esac
        shift
    done
    echo $t' --plan '${p}' --input "'${i}'" --output "'${o}'" --log-file '${l}
}

# ----------------------------------------------------------------------------
# Populate template variable.
#       - String $1: Variable to populate.
#       - String $2: Value to add.
#       - String $3: Corresponding key. (default: "ID")
#
# Your variable to populate must have double brace. (ie. {{ID}})
#
populate_template(){
    local string=$1
    local value=$2
    local key=${3:-ID}
    echo $(echo $string | sed -e "s/{{$key}}/$value/g")
}

# ----------------------------------------------------------------------------
# Function to gets json entry and to remove leading and trailing quote.
# Inputs:
#       - String $1: Entry of JSON file like ".default.threads"
#       - String $2: JSON config file.
#
get_json_entry(){
    local jq_output="$(jq "${1}" ${2})"
    echo $(sed -e 's/^"//' -e 's/"$//' <<<"${jq_output}")
}

# ----------------------------------------------------------------------------
# Initiate variable of a wrapper.
# Inputs:
#       - Array $@: Arguments of a wrapper.
#
init_wrapper(){
    local key
    while [[ $# > 0 ]]; do
        key="$1"
        case "${key}" in
            -p|--plan)
                PLAN="$2"
                shift
                ;;
            -i|--input)
                INPUT="$2"
                shift
                while [[ $2 != "-"* ]]; do
                    INPUT=$(printf '%s %s' $INPUT $2)
                    shift
                done
                ;;
            -o|--output)
                OUTPUT="$2"
                shift
                while [[ $2 != "-"* ]]; do
                    OUTPUT=$(printf '%s %s' $OUTPUT $2)
                    shift
                done
                ;;
            -c|--config)
                CONFIG="$2"
                shift
                ;;
            -l|--log-file)
                LOG="$2"
                shift
                ;;
            *)
                ;;
        esac
        shift
    done
}

# ----------------------------------------------------------------------------
# Function to gets well formated resources requested by a task.
# Inputs:
#       - String $1: Tool executable.
#       - String $2: JSON config file.
#
get_cluster_resources(){
    local tool=$1
    local config=$2
    # format for the -l option of qsub
    opt=$(jq '.'${tool}'' "${config}" | awk '
    {
        if ($1 !~ /[{}]/){
            sub(":",""); gsub(",",""); gsub(/"/, "");
            arr[$1] = $2
        }
    }END{
        print "nodes="arr["nodes"]":ppn="arr["threads"]",mem="arr["memory"]",walltime="arr["time"]
    }')
    echo ${opt}
}

# ----------------------------------------------------------------------
# Function to run bash as qsub or not.
# Inputs:
#       - String $1: Command line to run as a String.
#       - String $2: JSON config file.
#       - Int $3: PID of a previous job.
#
run_bash(){
    local cmd=($1)
    local config=$2
    local pid=${3:-None}
    # remove path and remove prefix
    local tool=${cmd[0]##*/}
    tool=${tool%.sh}
    tool=${tool%-bash}
    if [[ -n ${CLUSTER} ]]; then
        local opt=$(get_cluster_resources ${tool} ${config})
        opt=(-m ae -j oe -N "rawqc_${tool}" -q batch -l "${opt}" -V -d $CWD)
        if [[ ${NB_SAMPLE} -gt 1 && "${cmd[@]}" != *"expand("* ]]; then
            opt+=(-t 1-${NB_SAMPLE})
        fi
        if [[ "${pid}" == *"[]" ]]; then
            opt+=(-W depend=afterokarray:${pid})
        elif [[ "${pid}" != "None" ]]; then
            opt+=(-W depend=afterok:${pid})
        fi
        pid=$(echo "bash ${cmd[@]} --config ${config}" | qsub "${opt[@]}")
        echo ${pid%%.*}
    else 
        eval "bash ${cmd[@]} --config ${config}" && echo "None"
    fi
}
