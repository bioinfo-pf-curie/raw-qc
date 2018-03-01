#!/usr/bin/env bash
## RAW-QC Research Pipeline Workflow
## Copyleft 2017 Institut Curie
## Author(s): Mathieu VALADE
## Contact: mathieu.valade@curie.fr
## This software is distributed without any guarantee under the terms of the GNU General
## Public License, either Version 2, June 1991 or Version 3, June 2007.


# source bashrc_bioinfo script #
#source "/bioinfo/pipelines/dm-toolbox/prod/bashrc/bashrc_bioinfo"
#if [[ ${?} -ne 0 ]]; then
#    echo "Source failed for bashrc_bioinfo: /bioinfo/pipelines/dm-toolbox/prod/bashrc/bashrc_bioinfo"
#    exit 1;
#fi

#set +x


# set variables #
state="begin"
dataset_id="{DATASET_ID}"
snakemake_bin_dir="/bioinfo/local/build/Centos/python/python-3.6.1/bin/snakemake"
python_bin_dir="/bioinfo/local/build/Centos/python/python-2.7.13/bin/python2.7"


# manage parameters #
if [[ ${#} -eq 0 ]];then
    echo >&2 "ERROR: Usage: ${0} [-c CONFIG_TEMPLATE] [-r RUN] [-e ENV] [-i ILLUMINA_DIR] [-s ILLUMINA_SEQUENCER] [-d RIMS_ID] [-k KDI_PROJECT] [-t PROJECT_TYPE] [-o SCOPE] [-m DEMAND] [-y DATATYPE] [-a CONDA_PATH] [-p SPECIES] [-u UNLOCK] [-f OUTPUT_PATH]"
    exit 9
fi

while getopts ":c:r:e:i:s:d:k:t:o:m:y:a:p:u:f:" option
do
    case "${option}" in
    c)    CONFIG_TEMPLATE=${OPTARG};;
    r)    RUN=${OPTARG};;
    e)    ENV=${OPTARG};;
    i)    ILLUMINA_DIR=${OPTARG};;
    s)    ILLUMINA_SEQUENCER=${OPTARG};;
    d)    RIMS_ID=${OPTARG};;
    k)    KDI_PROJECT=${OPTARG};;
    t)    PROJECT_TYPE=${OPTARG};;
    o)    SCOPE=${OPTARG};;
    m)    DEMAND=${OPTARG};;
    y)    DATATYPE=${OPTARG};;
    a)    CONDA_PATH=${OPTARG};;
    p)    SPECIES=${OPTARG};;
    u)    UNLOCK=${OPTARG};;
    f)    OUTPUT_PATH=${OPTARG};;
    \?)   echo >&2 "ERROR: '${OPTARG}': invalid argument. Usage: ${0} [-c CONFIG_TEMPLATE] [-r RUN] [-e ENV] [-i ILLUMINA_DIR] [-s ILLUMINA_SEQUENCER] [-d RIMS_ID] [-k KDI_PROJECT] [-t PROJECT_TYPE] [-o SCOPE] [-m DEMAND] [-y DATATYPE] [-a CONDA_PATH] [-p SPECIES] [-u UNLOCK] [-f OUTPUT_PATH]"
          exit 10;;
    esac
    shift $((OPTIND-1)); OPTIND=1
done

SPECIES=${SPECIES/_/ }

# check parameters values #
if [[ -z ${CONFIG_TEMPLATE} ]] || [[ -z ${UNLOCK} ]] || [[ -z ${RUN} ]] || [[ -z ${ENV} ]] || [[ -z ${ILLUMINA_DIR} ]] || [[ -z ${ILLUMINA_SEQUENCER} ]] || [[ -z ${KDI_PROJECT} ]] || [[ -z ${PROJECT_TYPE} ]] || [[ -z ${SCOPE} ]] || [[ -z ${DEMAND} ]] || [[ -z ${DATATYPE} ]] || [[ -z ${CONDA_PATH} ]] || [[ -z ${SPECIES} ]] || [[ -z ${OUTPUT_PATH} ]]; then
    echo "ERROR : There is one or many empty argument(s)"
    exit 1
fi


# create RAWQC_PATH #
filepath=$(realpath -s ${0})
dirpath=$(dirname ${filepath})
# delete last folder name of the path
RAWQC_PATH=$(echo $dirpath | sed 's|/[^/]\+$|/|g')
echo "RAWQC_PATH: ${RAWQC_PATH}"


# check ILLUMINA_SEQUENCER value #
if [[ ${ILLUMINA_SEQUENCER,,} == "miseq" ]]
then
    illumina_file="CompletedJobInfo.xml"
elif [[ ${ILLUMINA_SEQUENCER,,} == "hiseq" ]]
then
    illumina_file="Basecalling_Netcopy_complete.txt"
elif [[ ${ILLUMINA_SEQUENCER,,} == "nextseq" ]]
then
    illumina_file="RunCompletionStatus.xml"
else
    echo "ERROR: Wrong value for ILLUMINA_SEQUENCER argument : '${ILLUMINA_SEQUENCER}'. Values availables are 'miseq' or 'hiseq' or 'nextseq'"
    exit 1;
fi


# check ENV value #
if [[ ${ENV,,} == "dev" ]]
then
    export PYTHONPATH="/bioinfo/pipelines/SOAPclient/python/kdi_dev/instance"
    export GAINGROUP="/bioinfo/local/bin/gaingroup -g w-ngsdm-gd"
elif [[ ${ENV,,} == "valid" ]]
then
    export PYTHONPATH="/bioinfo/pipelines/SOAPclient/python/kdi_valid/instance"
    export GAINGROUP="/bioinfo/local/bin/gaingroup -g w-ngsdm-gv"
elif [[ ${ENV,,} == "prod" ]]
then
    export PYTHONPATH="/bioinfo/pipelines/SOAPclient/python/kdi_prod/instance"
    export GAINGROUP="/bioinfo/local/bin/gaingroup -g w-ngsdm-gp"
else
    echo "ERROR: Wrong 'ENV' value in argument, the 'ENV' values availables are 'dev', 'valid', 'prod'"
    exit 1;
fi


# check DATATYPE value #
if [[ ! ${DATATYPE^^} == "PE" ]] && [[ ! ${DATATYPE^^} == "SE" ]]; then
    echo "ERROR : Wrong value for 'DATATYPE' argument : '${DATATYPE}'. Values availables are 'SE' or 'PE'"
    exit 1;
fi


# check PROJECT value #
source <(source ${CONFIG_TEMPLATE}; printf %s\\n "PROJECT=\"${PROJECT}\"";)
if [[ -z ${PROJECT} ]]; then
    echo "ERROR : Empty value for PROJECT argument: '${PROJECT}'"
    exit 1
fi


# create and check output folder #
if [[ ! -d ${OUTPUT_PATH} ]] && [[ ! -z ${OUTPUT_PATH} ]]
then
    mkdir -p ${OUTPUT_PATH}
elif [[ -z ${OUTPUT_PATH} ]]
then
    echo "ERROR: empty variable OUTPUT_PATH: ${OUTPUT_PATH}"
    exit 1
fi

output_dir=${OUTPUT_PATH}/${PROJECT}-${RUN}
mkdir -p ${output_dir}/
if [[ ! -d ${output_dir}/ ]]; then
    echo -e "ERROR: Failed to create the directory ${output_dir}"
    exit 1
fi

LOG=${output_dir}/raw-qc-${RUN}.log

# copy and fill the workflow config template #
config_file=$(basename ${CONFIG_TEMPLATE})
config=${output_dir}/${RUN}_${config_file}

cp ${CONFIG_TEMPLATE} ${config}
echo "cp ${CONFIG_TEMPLATE} ${config}"
if [[ ! -f ${config} ]]; then
	echo -e "\nFailed to copy the file ${config}\n"
	exit 1
fi

SEQUENCER=$(echo ${ILLUMINA_SEQUENCER} | sed -e 's/-zebulon//')

sed -i "s|{RUN}|${RUN}|g" ${config}
sed -i "s|{ENV}|${ENV,,}|g" ${config}
sed -i "s|{ILLUMINA_DIR}|${ILLUMINA_DIR}|g" ${config}
sed -i "s|{ILLUMINA_FILE}|${illumina_file}|g" ${config}
sed -i "s|{SEQUENCER}|${SEQUENCER}|g" ${config}
sed -i "s|{RIMS_ID}|${RIMS_ID:-}|g" ${config}
sed -i "s|{KDI_PROJECT}|${KDI_PROJECT}|g" ${config}
sed -i "s|{PROJECT_TYPE}|${PROJECT_TYPE}|g" ${config}
sed -i "s|{SCOPE}|${SCOPE}|g" ${config}
sed -i "s|{DEMAND}|${DEMAND}|g" ${config}
sed -i "s|{DATATYPE}|${DATATYPE^^}|g" ${config}
sed -i "s|{CONDA_PATH}|${CONDA_PATH}|g" ${config}


# source workflow config file #
{
    source ${config}
} || {
    echo >&2 "ERROR: no such file: ${config}"
    exit 11
}


# check QUEUE value #
if [[ ! ${QUEUE,,} == "batch" ]] && [[ ! ${QUEUE,,} == "diag" ]]
then
    echo "ERROR : Wrong value for QUEUE argument : '${QUEUE}'. Values availables are 'diag' or 'batch'" &>>${LOG}
    exit 1;
fi


# check KDI value #
if [[ ! ${KDI,,} == "yes" ]] && [[ ! ${KDI,,} == "no" ]]; then
    echo "ERROR : Wrong value for KDI argument : '${KDI}'. Values availables are 'yes' or 'no'" &>>${LOG}
    exit 1;
fi


# print variables #
echo "RAWQC_PATH:${RAWQC_PATH}; OUTPUT_PATH:${OUTPUT_PATH}; ENV:${ENV}; RUN:${RUN}; PROJECT:${PROJECT}; KDI:${KDI}; KDI_PROJECT:${KDI_PROJECT}; ILLUMINA_REF:${ILLUMINA_REF}; LOG:${LOG}; QUEUE:${QUEUE}; DEMULTIPLEXING:${DEMULTIPLEXING}; RIMS_ID:${RIMS_ID:-}; STEP:${STEP}; SCOPE:${SCOPE}; PROJECT_TYPE:${PROJECT_TYPE}; DEMAND:${DEMAND}; DATATYPE=${DATATYPE}; UNLOCK:${UNLOCK}; ILLUMINA_SEQUENCER:${ILLUMINA_SEQUENCER}; RESEARCH_RULES_PATH:${RESEARCH_RULES_PATH}" &>>${LOG}


# workflow launch #
date=$(date +'%d/%m/%y-%H:%M:%S')
echo "############################## NEW LAUNCH : ${date} ##############################" &>>${LOG}

# check RESEARCH_RULES_PATH value #
#source <(source ${CONFIG_TEMPLATE}; printf %s\\n "RESEARCH_RULES_PATH=\"${RESEARCH_RULES_PATH}\"";)
if [[ -z ${RESEARCH_RULES_PATH} ]]; then
    echo "ERROR : Empty value for PROJECT argument: '${RESEARCH_RULES_PATH}'"
    exit 1
fi

# launch rims metadata conf script #
rims_metadata_conf_command="${GAINGROUP} ${python_bin_dir} ${RESEARCH_RULES_PATH}/rims_metadata_parser_conf.py -o ${output_dir} -l ${LOG} -e ${ENV,,} -r ${RUN} --demand ${DEMAND} &>>${LOG}"
echo ${rims_metadata_conf_command} &>>${LOG}
{
    eval ${rims_metadata_conf_command} &>>${LOG}
} || {
    echo >&2 "ERROR: non 0 exit status: ${rims_metadata_conf_command}" &>>${LOG}
    exit 21
}


if [[ -f ${output_dir}/${RUN}-rims_metadata_conf.tsv ]]; then
    biological_application=$(awk -F"(\t)" '{ if ($1 == "biological_application") print $2 }' ${output_dir}/${RUN}-rims_metadata_conf.tsv) &>>${LOG}
    analysis_type=$(awk -F"(\t)" '{ if ($1 == "analysis_type") print $2 }' ${output_dir}/${RUN}-rims_metadata_conf.tsv) &>>${LOG}
    #kdi_species=$(awk -F"(\t)" '{ if ($1 == "species") print $2 }' ${output_dir}/${RUN}-rims_metadata_conf.tsv) &>>${LOG}
    kdi_species=${SPECIES}
else
    echo "ERROR: the file '${output_dir}/${RUN}-rims_metadata_conf.tsv' doesn't exist, the script '${RAWQC_PATH}/raw-qc_snakemake/rims_metadata_parser_conf.py' may be in error state" &>>${LOG}
    exit 1
fi

sed -i "s|{KDI_SPECIES}|${kdi_species}|g" ${config}


# source workflow config file #
{
    source ${config}
} || {
    echo >&2 "ERROR: no such file: ${config}"
    exit 11
}


# set commands #
demultiplexCmd="${snakemake_bin_dir} -s ${RAWQC_PATH}/raw-qc_snakemake/snakefile_preprocessing_rawqc --configfile ${OUTPUT_PATH}/${PROJECT}-${RUN}/config_raw-qc.yaml --latency-wait 60 --max-jobs-per-second 2 --verbose --cluster 'qsub {params.cluster}' -j 59 &>>${LOG}";
snakemakeAnalysis="${snakemake_bin_dir} -s ${RAWQC_PATH}/raw-qc_snakemake/snakefile_rawqc_pipeline --configfile ${OUTPUT_PATH}/${PROJECT}-${RUN}/config_raw-qc.yaml --latency-wait 60 --max-jobs-per-second 2 --verbose --cluster 'qsub -V {params.cluster}' -j 59 &>>${LOG}";
snakemakeIntegration="${snakemake_bin_dir} -s ${RAWQC_PATH}/raw-qc_snakemake/snakefile_kdi_rawqc --configfile ${OUTPUT_PATH}/${PROJECT}-${RUN}/config_raw-qc.yaml --latency-wait 60 --max-jobs-per-second 2 --cluster 'qsub {params.cluster}' -j 59 &>>${LOG}";
fillConfigCmd="${RAWQC_PATH}/raw-qc_snakemake/fill_raw-qc_pipeline_config_snakemake.sh -c ${config} -b \"${biological_application}\" -a \"${analysis_type}\" -i ${ILLUMINA_FILE} -g ${GAINGROUP} -r ${RAWQC_PATH} -o ${OUTPUT_PATH} &>>${LOG}";
unlockCmd="${snakemake_bin_dir} -s ${RAWQC_PATH}/raw-qc_snakemake/snakefile_preprocessing_rawqc --configfile ${OUTPUT_PATH}/${PROJECT}-${RUN}/config_raw-qc.yaml --verbose --unlock --cluster 'qsub {params.cluster}' -j 59 &>>${LOG}";
if [[ -n ${RIMS_ID:-} ]]; then
    graniCall="echo \"Calling grani services\" &>>${LOG} && cd /bioinfo/pipelines/grani/${ENV}/ && ./grani_create_run_final.pl -ir \"${RIMS_ID:-}\" -di \"${dataset_id}\" -rn \"${RUN}\" -pd \"${PATH}\" -lf \"${LOG}\" -ip \"/data/transfert/Illumina/${ILLUMINA_REF}\" -st \"${state}\" &>>${LOG}";
fi


# workflow conditions #
# config management
if [[ ! -f ${OUTPUT_PATH}/${PROJECT}-${RUN}/config_rawqc_centos.yaml ]]; then
    echo "fillConfigCmd : ${fillConfigCmd}" &>>${LOG}
    eval ${fillConfigCmd}
    error_status=${?}
    if [[ ${error_status} -ne 0 ]]; then
        echo "ERROR: the fillConfigCmd is in error state; error status: ${error_status}" &>>${LOG}
        exit 15;
    fi
else
    echo "INFO : The config file '${OUTPUT_PATH}/${PROJECT}-${RUN}/config_rawqc_centos.yaml' is already present. The fillConfigCmd (${fillConfigCmd}) isn't launched." &>>${LOG}
fi

if [[ ${UNLOCK,,} == "yes" ]]; then
    # unlock mode
    echo "INFO: UNLOCK MODE" &>>${LOG}
    echo "unlockCmd: ${unlockCmd}" &>>${LOG}
    eval ${unlockCmd}
    exit;
elif [[ ${UNLOCK,,} == "no" ]]; then
    # pipeline mode
    echo "INFO: PIPELINE MODE" &>>${LOG}
    if [[ ${STEP} == "analysis" ]]; then
        # demultiplex test & call
        state="demultiplexing"
        if [[ ${DEMULTIPLEXING,,} == "no" ]]; then
            echo "INFO: The DEMULTIPLEXING argument is \'no\' (${DEMULTIPLEXING}), the demultiplexing step isn't launch" &>>${LOG}
        elif [[ ${DEMULTIPLEXING,,} == "yes" ]]; then
            echo "${state} : ${demultiplexCmd}" &>>${LOG}
            eval ${demultiplexCmd}
            error_status=${?}
            if [[ ${error_status} -ne 0 ]]; then
                state="analysis_error" &>>${LOG}
                if [[ -n ${RIMS_ID:-} ]]; then
                    {
                        eval ${graniCall}
                    } || {
                        echo "ERROR: Grani failed at analysisError call" &>>${LOG}
                        exit 30;
                    }
                fi
                exit 1;
            fi
        else
            echo "ERROR : Wrong DEMULTIPLEXING argument (yes, no)" &>>${LOG}
            if [[ -n ${RIMS_ID:-} ]]; then
                {
                    eval ${graniCall}
                } || {
                    echo "ERROR: Grani failed at analysisError call" &>>${LOG}
                    exit 30;
                }
            fi
            exit 1;
        fi
        # snakemake analysis step
        state="analysis"
        echo "${state} : ${snakemakeAnalysis}" &>>${LOG}
        source ${CONDA_PATH}/activate raw-qc
        eval ${snakemakeAnalysis}
        error_status=${?}
        source deactivate raw-qc
        if [[ ${error_status} -ne 0 ]]; then
            state="analysis_error" &>>${LOG}
            echo "state=${state}; error status: ${error_status}" &>>${LOG}
            if [[ -n ${RIMS_ID:-} ]]; then
                {
                    eval ${graniCall}
                } || {
                    echo "ERROR: Grani failed at analysisError call" &>>${LOG}
                    exit 30;
                }
            fi
            exit 2;
        else
            state="analysis_success" &>>${LOG}
            echo "state=${state}" &>>${LOG}
            if [[ -n ${RIMS_ID:-} ]]; then
                {
                    eval ${graniCall}
                } || {
                    echo "ERROR: Grani failed at analysisSuccess call" &>>${LOG}
                    exit 20;
                }
            fi
            STEP="integration"
        fi
    fi
    if [[ ${KDI} == "yes" ]]; then
        if [[ ${STEP} == "integration" ]]; then
            # snakemake integration step
            state="integration"
            echo "${state}: ${snakemakeIntegration}" &>>${LOG}
            eval ${snakemakeIntegration}
            error_status=${?}
            if [[ ${error_status} -ne 0 ]]; then
                state="integration_error" &>>${LOG}
                echo "state=${state}; error status: ${error_status}" &>>${LOG}
                if [[ -n ${RIMS_ID:-} ]]; then
                    {
                        dataset_id=$(awk -v ligne=1 ' NR == ligne {print $1}' ${output_dir}/kdi_create_dataset_rule_ok.txt) &>>${LOG}
                    } || {
                        echo "ERROR: failed to catch dataset_id value in the file '${output_dir}/kdi_create_dataset_rule_ok.txt'" &>>${LOG}
                    }
                    {
                        eval ${graniCall}
                    } || {
                       echo "ERROR: Grani failed at integrationError call" &>>${LOG}
                       exit 50;
                    }
                fi
                exit 3;
            else
                state="integration_success" &>>${LOG}
                echo "state=${state}" &>>${LOG}
                if [[ -n ${RIMS_ID:-} ]]; then
                    {
                        dataset_id=$(awk -v ligne=1 ' NR == ligne {print $1}' ${output_dir}/kdi_create_dataset_rule_ok.txt) &>>${LOG}
                    } || {
                        echo "ERROR: failed to catch dataset_id value in the file '${output_dir}/kdi_create_dataset_rule_ok.txt'" &>>${LOG}
                    }
                    {
                        eval ${graniCall}
                    } || {
                        echo "ERROR: Grani failed at integrationSuccess call" &>>${LOG}
                        exit 40;
                    }
                fi
            fi
        else
            echo "ERROR: Wrong STEP argument (analysis, integration)" &>>${LOG}
            exit 1;
        fi
    else
        echo "INFO: The value 'KDI' is 'no' (${KDI}) then there is no integration step" &>>${LOG}
    fi
else
    echo "ERROR: Wrong value for UNLOCK argument : '${UNLOCK}'. Values availables are 'yes' or 'no'" &>>${LOG}
    exit 1;
fi
