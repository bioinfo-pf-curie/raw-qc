#!/bin/bash
### source du bashrc_bioinfo
source "/bioinfo/pipelines/dm-toolbox/prod/bashrc/bashrc_bioinfo"
if [[ ${?} -ne 0 ]]; then
    echo "Source failed for bashrc_bioinfo: /bioinfo/pipelines/dm-toolbox/prod/bashrc/bashrc_bioinfo"
    exit 1;
fi

set +x


if [ ${#} -eq 0 ];then
    echo >&2 "ERROR: Usage: ${0} [-c CONFIG] [-b BIOLOGICAL_APPLICATION] [-a ANALYSIS_TYPE] [-i ILLUMINA_FILE] [-g GAINGROUP] [-r RAWQC_PATH]"
    exit 9
fi

while getopts ":c:b:a:i:g:r:" option
do
    case "$option" in
    c)    CONFIG=$OPTARG;;
    b)    BIOLOGICAL_APPLICATION=$OPTARG;;
    a)    ANALYSIS_TYPE=$OPTARG;;
    i)    ILLUMINA_FILE=$OPTARG;;
    g)    GAINGROUP=$OPTARG;;
    r)    RAWQC_PATH=$OPTARG;;
    \?)   echo >&2 "ERROR: $OPTARG': invalid argument. Usage: ${0} [-c CONFIG] [-b BIOLOGICAL_APPLICATION] [-a ANALYSIS_TYPE] [-i ILLUMINA_FILE] [-g GAINGROUP] [-r RAWQC_PATH]"
        exit 1;;
    esac
    shift $((OPTIND-1)); OPTIND=1
done

# source the workflow config file #
{
    source $CONFIG
} || {
    echo >&2 "ERROR: no such file: $CONFIG"
    exit 11
}

LOG_PATH=$OUTPUT_PATH/${RUN}_fill_raw-qc_pipeline_config_snakemake.log;
echo "PROJECT:$PROJECT RUN:$RUN ILLUMINA_REF:$ILLUMINA_REF KDI:$KDI KDI_PROJECT:$KDI_PROJECT ENV:$ENV OUTPUT_PATH:$OUTPUT_PATH RAWQC_PATH:$RAWQC_PATH LOG_PATH:$LOG_PATH PROJECT_TYPE:$PROJECT_TYPE SCOPE:$SCOPE QUEUE:$QUEUE DEMAND:$DEMAND KDI_SPECIES=$KDI_SPECIES DATATYPE:$DATATYPE ILLUMINA_FILE:$ILLUMINA_FILE RESEARCH_RULES_PATH:$RESEARCH_RULES_PATH ILLUMINA_SEQUENCER:$ILLUMINA_SEQUENCER BIOLOGICAL_APPLICATION:${BIOLOGICAL_APPLICATION} ANALYSIS_TYPE:${ANALYSIS_TYPE}" &>> $LOG_PATH
if [[ -z $PROJECT ]] || [[ -z $RUN ]] || [[ -z $ILLUMINA_REF ]] || [[ -z $KDI ]] || [[ -z $KDI_PROJECT ]] || [[ -z $ENV ]] || [[ -z $OUTPUT_PATH ]] || [[ -z $RAWQC_PATH ]] || [[ -z $LOG_PATH ]] || [[ -z $PROJECT_TYPE ]] || [[ -z $SCOPE ]] || [[ -z $QUEUE ]] || [[ -z $KDI_SPECIES ]] || [[ -z $DEMAND ]] || [[ -z $DATATYPE ]] || [[ -z $ILLUMINA_FILE ]] || [[ -z $RESEARCH_RULES_PATH ]] || [[ -z $ILLUMINA_SEQUENCER ]] || [[ -z $BIOLOGICAL_APPLICATION ]] || [[ -z $ANALYSIS_TYPE ]]
then
    echo "ERROR : There is/are empty argument(s)" &>> $LOG_PATH
    exit 1
fi

if [[ ! $KDI == "yes" ]] && [[ ! $KDI == "no" ]]
then
    echo "ERROR : wrong value for KDI: $KDI. Values available are 'yes' or 'no'" &>> $LOG_PATH
    exit 1
fi

if [[ ! -d $RAWQC_PATH ]]
then
    echo "ERROR : empty path RAWQC_PATH: $RAWQC_PATH" &>> $LOG_PATH
    exit 1
fi

if [[ ! ${DATATYPE^^} == "SE" ]] && [[ ! ${DATATYPE^^} == "PE" ]]
then
    echo "ERROR : wrong value for DATATYPE: '${DATATYPE^^}'. Values available are 'SE' or 'PE'" &>> $LOG_PATH
    exit 1
fi

mkdir -p $OUTPUT_PATH/$PROJECT-$RUN/ 2>$LOG_PATH
if [[ ! -f $OUTPUT_PATH/$PROJECT-$RUN/config_raw-qc.yaml ]]
then
    cp $RAWQC_PATH/raw-qc_snakemake/config_raw-qc.yaml $OUTPUT_PATH/$PROJECT-$RUN/. 2>> $LOG_PATH
    echo "cp $RAWQC_PATH/raw-qc_snakemake/config_raw-qc.yaml $OUTPUT_PATH/$PROJECT-$RUN/."  &>> $LOG_PATH
fi
CONFIG_SNAKEMAKE_FILE=$OUTPUT_PATH/$PROJECT-$RUN/config_raw-qc.yaml
sed -i "s|{{RUN}}|$RUN|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH &&
sed -i "s|{{OUTPUT_PATH}}|$OUTPUT_PATH|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH &&
sed -i "s|{{ILLUMINA_REF}}|$ILLUMINA_REF|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH &&
sed -i "s|{{PROJECT_TYPE}}|$PROJECT_TYPE|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH &&
sed -i "s|{{KDI_PROJECT}}|$KDI_PROJECT|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH &&
sed -i "s|{{RAWQC_PATH}}|$RAWQC_PATH|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH &&
sed -i "s|{{SCOPE}}|$SCOPE|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH &&
sed -i "s|{{ENV}}|$ENV|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH &&
sed -i "s|{{KDI_SPECIES}}|$KDI_SPECIES|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH &&
sed -i "s|{{QUEUE}}|$QUEUE|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH &&
sed -i "s|{{DEMAND}}|$DEMAND|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH &&
sed -i "s|{{DATATYPE}}|${DATATYPE^^}|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH
sed -i "s|{{ILLUMINA_FILE}}|$ILLUMINA_FILE|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH &&
sed -i "s|{{RESEARCH_RULES_PATH}}|$RESEARCH_RULES_PATH|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH &&
sed -i "s|{{ILLUMINA_SEQUENCER}}|$ILLUMINA_SEQUENCER|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH &&
sed -i "s|{{PROTOCOL}}|$BIOLOGICAL_APPLICATION|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH &&
sed -i "s|{{BIOLOGICAL_CATEGORY}}|$ANALYSIS_TYPE|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH

if [[ ${ENV,,} == "dev" ]]
then
    sed -i "s|{{GAINGROUP}}|d|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH
elif [[ ${ENV,,} == "valid" ]]
then
    sed -i "s|{{GAINGROUP}}|v|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH
elif [[ ${ENV,,} == "prod" ]]
then
    sed -i "s|{{GAINGROUP}}|p|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH
else
    echo "ERROR : Wrong env in arg (dev,valid,prod)"  &>> $LOG_PATH
    exit 1;
fi

if [[ $ILLUMINA_SEQUENCER == "hiseq" ]] || [[ $ILLUMINA_SEQUENCER == "nextseq" ]]
then
	sed -i "s|{{MEM_BCL2FASTQ}}|50Gb|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH
else
	sed -i "s|{{MEM_BCL2FASTQ}}|5Gb|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH
fi

