#!/bin/bash
### source du bashrc_bioinfo
#source "/bioinfo/pipelines/dm-toolbox/prod/bashrc/bashrc_bioinfo"
#if [[ $? -ne 0 ]]; then echo "Source failed for bashrc_bioinfo: /bioinfo/pipelines/dm-toolbox/prod/bashrc/bashrc_bioinfo"; exit 1; fi

#set +x




if [ $# -eq 0 ];then echo "Usage: $0 [-p PROJECT] [-r RUN] [-o OUTPUT_PATH] [-i ILLUMINA_REF] [-k KDI] [-j KDI_PROJECT] [-e ENV] [-n RAWQC_PATH] [-y monoproject/multiproject] [-s research/diag] [-q QUEUE] [-z KDI_SPECIES] [-d DEMAND] [-v DATATYPE] [-l ILLUMINA_FILE] [-u RESEARCH_RULES_PATH] [-w ILLUMINA_SEQUENCER]" ; exit 1 ; else ARG_LIST=($@) ; fi
## LONG ARGUMENTS PARSING  ##
for arg in ${ARG_LIST[@]}
do
    delim=""
    case "$arg" in
       --project) args="${args}-p ";;
       --run) args="${args}-r ";;
       --output) args="${args}-o ";;
       --illumina) args="${args}-i ";;
       --kdi) args="${args}-k ";;
       --kdiproject) args="${args}-j ";;
       --env) args="${args}-e ";;
       --raw-qc_path) args="${args}-n ";;
       --project_type) args="${args}-y ";;
       --scope) args="${args}-s ";;
       --queue) args="${args}-q ";;
       --demand) args="${args}-d ";;
       --kdi_species) args="${args}-z ";;
       --datatype) args="${args}-v ";;
       --illumina_file) args="${args}-l ";;
       --research_rules_path) args="${args}-u ";;
       --illumina_sequencer) args="${args}-w ";;
       *) [[ "${arg:0:1}" == "-" ]] || delim="\""
           args="${args}${delim}${arg}${delim} ";;
    esac
done

eval set -- $args
while getopts ":p:r:o:i:k:j:e:n:f:y:s:q:x:b:m:c:a:d:z:v:g:t:l:u:w:" option
do
    case "$option" in
    p)    PROJECT=$OPTARG;;
    r)    RUN=$OPTARG;;
    o)    OUTPUT_PATH=$OPTARG;;
    i)    ILLUMINA_REF=$OPTARG;;
    k)    KDI=$OPTARG;;
    j)    KDI_PROJECT=$OPTARG;;
    e)    ENV=$OPTARG;;
    n)    RAWQC_PATH=$OPTARG;;
    y)    PROJECT_TYPE=$OPTARG;;
    s)    SCOPE=$OPTARG;;
    q)    QUEUE=$OPTARG;;
    d)    DEMAND=$OPTARG;;
    z)    KDI_SPECIES=$OPTARG;;
    v)    DATATYPE=$OPTARG;;
    l)    ILLUMINA_FILE=$OPTARG;;
    u)    RESEARCH_RULES_PATH=$OPTARG;;
    w)    ILLUMINA_SEQUENCER=$OPTARG;;
    \?)   echo >&2 "Usage: $0 [-p PROJECT] [-r RUN] [-o OUTPUT_PATH] [-i ILLUMINA_REF] [-k KDI] [-j KDI_PROJECT] [-e ENV] [-n RAWQC_PATH] [-y monoproject/multiproject] [-s research/diag] [-q QUEUE] [-d DEMAND] [-z KDI_SPECIES] [-v DATATYPE] [-l ILLUMINA_FILE] [-u RESEARCH_RULES_PATH] [-w ILLUMINA_SEQUENCER]"
        exit 1;;
    esac
shift $((OPTIND-1)); OPTIND=1
done
LOG_PATH=$OUTPUT_PATH/${RUN}_fill_raw-qc_pipeline_config_snakemake.log;
echo "PROJECT:$PROJECT RUN:$RUN ILLUMINA_REF:$ILLUMINA_REF KDI:$KDI KDI_PROJECT:$KDI_PROJECT ENV:$ENV OUTPUT_PATH:$OUTPUT_PATH RAWQC_PATH:$RAWQC_PATH LOG_PATH:$LOG_PATH PROJECT_TYPE:$PROJECT_TYPE SCOPE:$SCOPE QUEUE:$QUEUE DEMAND:$DEMAND KDI_SPECIES=$KDI_SPECIES DATATYPE:$DATATYPE ILLUMINA_FILE:$ILLUMINA_FILE RESEARCH_RULES_PATH:$RESEARCH_RULES_PATH ILLUMINA_SEQUENCER:$ILLUMINA_SEQUENCER" &>> $LOG_PATH
if [[ -z $PROJECT ]] || [[ -z $RUN ]] || [[ -z $ILLUMINA_REF ]] || [[ -z $KDI ]] || [[ -z $KDI_PROJECT ]] || [[ -z $ENV ]] || [[ -z $OUTPUT_PATH ]] || [[ -z $RAWQC_PATH ]] || [[ -z $LOG_PATH ]] || [[ -z $PROJECT_TYPE ]] || [[ -z $SCOPE ]] || [[ -z $QUEUE ]] || [[ -z $KDI_SPECIES ]] || [[ -z $DEMAND ]] || [[ -z $DATATYPE ]] || [[ -z $ILLUMINA_FILE ]] || [[ -z $RESEARCH_RULES_PATH ]] || [[ -z $ILLUMINA_SEQUENCER ]]
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
sed -i "s|{{ILLUMINA_SEQUENCER}}|$ILLUMINA_SEQUENCER|g" $CONFIG_SNAKEMAKE_FILE 2>>$LOG_PATH

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
