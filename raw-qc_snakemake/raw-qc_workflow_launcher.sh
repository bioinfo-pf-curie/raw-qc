#!/bin/bash
## RAW-QC Research Pipeline Workflow
## Copyleft 2017 Institut Curie
## Author(s): Mathieu VALADE
## Contact: mathieu.valade@curie.fr
## This software is distributed without any guarantee under the terms of the GNU General
## Public License, either Version 2, June 1991 or Version 3, June 2007.



### source du bashrc_bioinfo
#source "/bioinfo/pipelines/dm-toolbox/prod/bashrc/bashrc_bioinfo"
#if [[ $? -ne 0 ]]; then echo "Source failed for bashrc_bioinfo: /bioinfo/pipelines/dm-toolbox/prod/bashrc/bashrc_bioinfo"; exit 1; fi

#set +x

# set variables
STATE="begin"
HAS_ERROR=0
DATASET_ID="{DATASET_ID}"

if [ $# -eq 0 ];then echo "Usage: $0 [-c CONFIG_FILE] [-u UNLOCK]" ; exit 1 ; else ARG_LIST=($@) ; fi
## LONG ARGUMENTS PARSING  ##
for arg in ${ARG_LIST[@]}
do
    delim=""
    case "$arg" in
       --config) args="${args}-c ";;
       --unlock) args="${args}-u ";;
       *) [[ "${arg:0:1}" == "-" ]] || delim="\""
           args="${args}${delim}${arg}${delim} ";;
    esac
done

eval set -- $args

while getopts ":c:u:" option
do
    case "$option" in
    c)    CONFIG=$OPTARG;;
    u)    UNLOCK=$OPTARG;;
    \?)   HAS_ERROR=1;;
    esac
shift $((OPTIND-1)); OPTIND=1
done
#if arguments miss
if [  $HAS_ERROR == 1 ]; then
    echo >&2 "Usage: $0 [-c CONFIG_FILE] [-u UNLOCK]"
    exit 10;
fi
source $CONFIG
LOG=$OUTPUT_PATH/$LOG
DATE=$(date +'%d/%m/%y-%H:%M:%S')
echo "############################## NEW LAUNCH : $DATE ##############################" &>> $LOG

filepath=$(realpath -s $0) &>> $LOG
dirpath=$(dirname $filepath) &>> $LOG
# on supprime le dernier dossier
RAWQC_PATH=$(echo $dirpath | sed 's|/[^/]\+$|/|g') &>> $LOG
echo "RAWQC_PATH: ${RAWQC_PATH}" >> $LOG

echo "RAWQC_PATH:${RAWQC_PATH}; OUTPUT_PATH:$OUTPUT_PATH; ENV:$ENV; RUN:$RUN; PROJECT:$PROJECT; KDI:$KDI; KDI_PROJECT:$KDI_PROJECT; ILLUMINA_REF:$ILLUMINA_REF; LOG:$LOG; QUEUE:$QUEUE; DEMULTIPLEXING:$DEMULTIPLEXING; RIMS_ID:$RIMS_ID; STEP:$STEP; SCOPE:$SCOPE; PROJECT_TYPE:$PROJECT_TYPE; KDI_SPECIES=$KDI_SPECIES; DEMAND:$DEMAND; DATATYPE=$DATATYPE; UNLOCK:$UNLOCK; ILLUMINA_SEQUENCER:$ILLUMINA_SEQUENCER; RESEARCH_FUNC_PATH:$RESEARCH_FUNC_PATH" &>> $LOG

if [[ ! ${QUEUE,,} == "batch" ]] && [[ ! ${QUEUE,,} == "diag" ]]
then
    echo "ERROR : Wrong value for QUEUE argument : '$QUEUE'. Values availables are 'diag' or 'batch'" &>> $LOG
    exit 1;
fi

if [[ ! ${ILLUMINA_SEQUENCER,,} == "miseq" ]]
then
    ILLUMINA_FILE="CompletedJobInfo.xml"
elif [[ ! ${ILLUMINA_SEQUENCER,,} == "hiseq" ]]
then
    ILLUMINA_FILE="Basecalling_Netcopy_complete.txt"
elif [[ ! ${ILLUMINA_SEQUENCER,,} == "nextseq" ]]
then
    ILLUMINA_FILE="RunCompletionStatus.xml"
else
    echo "ERROR : Wrong value for ILLUMINA_SEQUENCER argument : '$ILLUMINA_SEQUENCER'. Values availables are 'miseq' or 'hiseq' or 'nextseq'" &>> $LOG
    exit 1;
fi

if [[ ${ENV,,} == "dev" ]]
then
    GAINGROUP="/bioinfo/local/bin/gaingroup -g w-ngsdm-gd" 2>>$LOG_PATH
elif [[ ${ENV,,} == "valid" ]]
then
    GAINGROUP="/bioinfo/local/bin/gaingroup -g w-ngsdm-gv" 2>>$LOG_PATH
elif [[ ${ENV,,} == "prod" ]]
then
    GAINGROUP="/bioinfo/local/bin/gaingroup -g w-ngsdm-gp" 2>>$LOG_PATH
else
    echo "ERROR : Wrong env in arg (dev,valid,prod)"  &>> $LOG_PATH
    exit 1;
fi


SNAKEMAKE_BIN_DIR="/bioinfo/local/build/Centos/python/python-3.6.1/bin/snakemake"
# set commands
demultiplexCmd="${GAINGROUP} echo \"$SNAKEMAKE_BIN_DIR -s ${RAWQC_PATH}/raw-qc_snakemake/snakefile_preprocessing_rawqc --configfile $OUTPUT_PATH/$PROJECT-$RUN/config_raw-qc.yaml --latency-wait 60 --verbose --cluster 'qsub {params.cluster}' -j 59 &>> $LOG\" | qsub -q ${QUEUE} -N snakemake_master_RAW-QC_preprocessing -o $OUTPUT_PATH/$PROJECT-$RUN/snakemake_master_RAW-QC_preprocessing.out -e $OUTPUT_PATH/$PROJECT-$RUN/snakemake_master_RAW-QC_preprocessing.err -d $OUTPUT_PATH/$PROJECT-$RUN/ -l nodes=1:ppn=1,mem=1Gb"
snakemakeAnalysis="${GAINGROUP} echo \"$SNAKEMAKE_BIN_DIR -s ${RAWQC_PATH}/raw-qc_snakemake/snakefile_rawqc_pipeline --configfile $OUTPUT_PATH/$PROJECT-$RUN/config_raw-qc.yaml --latency-wait 60 --verbose --cluster 'qsub -V {params.cluster}' -j 59 &>> $LOG\" | qsub -q ${QUEUE} -N snakemake_master_RAW-QC_analysis -o $OUTPUT_PATH/$PROJECT-$RUN/snakemake_master_RAW-QC_analysis.out -e $OUTPUT_PATH/$PROJECT-$RUN/snakemake_master_RAW-QC_analysis.err -d $OUTPUT_PATH/$PROJECT-$RUN/ -l nodes=1:ppn=1,mem=1Gb"
snakemakeIntegration="${GAINGROUP} echo \"$SNAKEMAKE_BIN_DIR -s ${RAWQC_PATH}/raw-qc_snakemake/snakefile_kdi_rawqc --configfile $OUTPUT_PATH/$PROJECT-$RUN/config_raw-qc.yaml --latency-wait 60 --cluster 'qsub {params.cluster}' -j 59 &>> $LOG\" | qsub -q ${QUEUE} -N snakemake_master_RAW-QC_integration -o $OUTPUT_PATH/$PROJECT-$RUN/snakemake_master_RAW-QC_integration.out -e $OUTPUT_PATH/$PROJECT-$RUN/snakemake_master_RAW-QC_integration.err -d $OUTPUT_PATH/$PROJECT-$RUN/ -l nodes=1:ppn=1,mem=1Gb";
fillConfigCmd="${GAINGROUP} echo \"${RAWQC_PATH}/raw-qc_snakemake/fill_raw-qc_pipeline_config_snakemake.sh --project $PROJECT --run $RUN --output $OUTPUT_PATH --illumina $ILLUMINA_REF --kdi $KDI --kdiproject $KDI_PROJECT --env $ENV --raw-qc_path ${RAWQC_PATH} --project_type $PROJECT_TYPE --scope $SCOPE --queue $QUEUE --kdi_species $KDI_SPECIES --demand $DEMAND --datatype $DATATYPE --illumina_file $ILLUMINA_FILE --illumina_sequencer $ILLUMINA_SEQUENCER --research_rules_path $RESEARCH_FUNC_PATH &>> $LOG\" | qsub -q ${QUEUE} -N RAW-QC_fill_config_cmd -o $OUTPUT_PATH/$PROJECT-$RUN/RAW-QC_fill_config_cmd.out -e $OUTPUT_PATH/$PROJECT-$RUN/RAW-QC_fill_config_cmd.err -d $OUTPUT_PATH/$PROJECT-$RUN/ -l nodes=1:ppn=1,mem=1Gb"

if [[ ${UNLOCK,,} == "yes" ]]
then
    if [[ ${DEMULTIPLEXING,,} == "no" ]]
    then
        # create config
        if [[ ! -f $OUTPUT_PATH/$PROJECT-$RUN/config_raw-qc.yaml ]]
        then
            echo "fillConfigCmd : $fillConfigCmd" &>> $LOG
            pid_fillConfigCmd=$(eval $fillConfigCmd)
        else
            echo "INFO : The config file '$OUTPUT_PATH/$PROJECT-$RUN/config_raw-qc.yaml' is already present. The fillConfigCmd ($fillConfigCmd) isn't launched."  &>> $LOG
            pid_fillConfigCmd="no"
        fi
        unlockCmd="${GAINGROUP} echo \"$SNAKEMAKE_BIN_DIR -s ${RAWQC_PATH}/raw-qc_snakemake/snakefile_preprocessing_rawqc --configfile $OUTPUT_PATH/$PROJECT-$RUN/config_raw-qc.yaml --verbose --unlock --cluster 'qsub {params.cluster}' -j 59 &>> $LOG\" | qsub -q ${QUEUE} -N snakemake_master_RAW-QC_unlock -o $OUTPUT_PATH/$PROJECT-$RUN/snakemake_master_RAW-QC_unlock.out -e $OUTPUT_PATH/$PROJECT-$RUN/snakemake_master_RAW-QC_unlock.err -l nodes=1:ppn=1,mem=1Gb";
    elif [[ ${DEMULTIPLEXING,,} == "yes" ]]
    then
        # create config
        if [[ ! -f $OUTPUT_PATH/$PROJECT-$RUN/config_raw-qc.yaml ]]
        then
            echo "fillConfigCmd : $fillConfigCmd" &>> $LOG
            pid_fillConfigCmd=$(eval $fillConfigCmd)
        else
            echo "INFO : The config file '$OUTPUT_PATH/$PROJECT-$RUN/config_raw-qc.yaml' is already present. The fillConfigCmd ($fillConfigCmd) isn't launched."  &>> $LOG
            pid_fillConfigCmd="no"
        fi
        unlockCmd="${GAINGROUP} echo \"$SNAKEMAKE_BIN_DIR -s ${RAWQC_PATH}/raw-qc_snakemake/snakefile_preprocessing_rawqc --configfile $OUTPUT_PATH/$PROJECT-$RUN/config_raw-qc.yaml --verbose --unlock --cluster 'qsub {params.cluster}' -j 59 &>> $LOG\" | qsub -q ${QUEUE} -N snakemake_master_RAW-QC_unlock -o $OUTPUT_PATH/$PROJECT-$RUN/snakemake_master_RAW-QC_unlock.out -e $OUTPUT_PATH/$PROJECT-$RUN/snakemake_master_RAW-QC_unlock.err -l nodes=1:ppn=1,mem=1Gb";
    fi
    echo "LAUNCH : $unlockCmd" &>> $LOG
    if [[ ! $pid_fillConfigCmd == "no" ]]
    then
        unlockCmd="$unlockCmd -W depend=afterok:$pid_fillConfigCmd"
    fi
    eval $unlockCmd
    exit 1;
elif [[ ! ${UNLOCK,,} == "no" ]]
then
    echo "ERROR : Wrong value for UNLOCK argument : '$UNLOCK'. Values availables are 'yes' or 'no'" &>> $LOG
    exit 1;
fi


if [ $RIMS_ID != "no" ]
then
	graniCall='echo "Calling grani services" &>> $LOG && cd /bioinfo/pipelines/grani/$ENV/ && ./grani_create_run_final.pl -ir "$RIMS_ID" -di "$DATASET_ID" -rn "$RUN" -pd "$PATH" -lf "$LOG" -ip "/data/transfert/Illumina/$ILLUMINA_REF" -st "$STATE" &>> $LOG';
fi

if [[ ! ${KDI,,} == "yes" ]] && [[ ! ${KDI,,} == "no" ]]; then
    echo "ERROR : Wrong value for KDI argument : '$KDI'. Values availables are 'yes' or 'no'" &>> $LOG
    exit 1;
fi

if [ $STEP == "analysis" ]; then
    {
        mkdir -p $OUTPUT_PATH/$PROJECT-$RUN &&
        # create config
        if [[ ! -f $OUTPUT_PATH/$PROJECT-$RUN/config_raw-qc.yaml ]]
        then
            echo "fillConfigCmd : $fillConfigCmd" &>> $LOG
            pid_fillConfigCmd=$(eval $fillConfigCmd)
        else
            echo "INFO : The config file '$OUTPUT_PATH/$PROJECT-$RUN/config_raw-qc.yaml' is already present. The fillConfigCmd ($fillConfigCmd) isn't launched."  &>> $LOG
            pid_fillConfigCmd="no"
        fi
        # demultiplex test & call
        STATE="demultiplexing"
        if [[ ${DEMULTIPLEXING,,} == "no" ]]
        then
            echo "The DEMULTIPLEXING argument is \'no\' ($DEMULTIPLEXING), the demultiplexing step isn't launch" &>> $LOG
        elif [[ ${DEMULTIPLEXING,,} == "yes" ]]
        then
            echo "$STATE : $demultiplexCmd" &>> $LOG
            if [[ ! $pid_fillConfigCmd == "no" ]]
            then
                demultiplexCmd="$demultiplexCmd -W depend=afterok:$pid_fillConfigCmd"
            fi
            pid_demultiplex=$(eval $demultiplexCmd)
            if [ $? -ne 0 ]
            then
                STATE="analysis_error" &>> $LOG;
                if [ $RIMS_ID != "no" ]
				then
                	eval $graniCall
                fi
                exit 1;
            fi
        else
            echo "ERROR : Wrong DEMULTIPLEXING argument (yes, no)" &>> $LOG
            if [ $RIMS_ID != "no" ]
            then
            	eval $graniCall
            fi
            exit 1;
        fi
        # snakemake analysis step
        STATE="analysis"
        echo "$STATE : $snakemakeAnalysis" &>> $LOG
        if [[ ${DEMULTIPLEXING,,} == "yes" ]]
        then
            snakemakeAnalysis="$snakemakeAnalysis -W depend=afterok:$pid_demultiplex"
        else
            if [[ ! $pid_fillConfigCmd == "no" ]]
            then
                snakemakeAnalysis="$snakemakeAnalysis:$pid_fillConfigCmd"
            fi
        fi
        source $CONDA_PATH/activate raw-qc
        pid_analysis=$(eval $snakemakeAnalysis)
        source deactivate raw-qc
    } || {
        STATE="analysis_error" &>> $LOG;
        if [ $RIMS_ID != "no" ]
        then
        	eval $graniCall
        fi
        exit 2;
    }

    {
    	if [ $RIMS_ID != "no" ]
    	then
        	eval $graniCall
        fi
        STEP="integration"
    } || {
        echo "Grani failed at analysisSuccess call" &>> $LOG
        exit 20;
    }
fi
if [[ $KDI == "yes" ]]; then
    if [ $STEP == "integration" ]; then
        {
            # snakemake itnegration step
            STATE="integration"
            echo "$STATE : $snakemakeIntegration" &>> $LOG
            snakemakeIntegration="$snakemakeIntegration -W depend=afterok:$pid_analysis"
            if [[ ! $pid_fillConfigCmd == "no" ]]
            then
                snakemakeIntegration="$snakemakeIntegration:$pid_fillConfigCmd"
            fi
            pid_integration=$(eval $snakemakeIntegration)
            if [ $RIMS_ID != "no" ]
            then
                DATASET_ID=$(${GAINGROUP} echo \"awk -v ligne=1 ' NR == ligne { print $1}' $OUTPUT_PATH/$PROJECT-$RUN/kdi_create_dataset_rule_ok.txt\" | qsub -q ${QUEUE} -N snakemake_master_dataset_id -o $OUTPUT_PATH/$PROJECT-$RUN/snakemake_master_dataset_id.out -e $OUTPUT_PATH/$PROJECT-$RUN/snakemake_master_dataset_id.err -d $OUTPUT_PATH/$PROJECT-$RUN/ -l nodes=1:ppn=1,mem=1Gb -W depend=afterok:$pid_integration)
            fi
        } || {
            STATE="integration_error" &>> $LOG;
            if [ $RIMS_ID != "no" ]
            then
            	eval $graniCall
            fi
            exit 3;
        }

        {
        	if [ $RIMS_ID != "no" ]
        	then
            	eval $graniCall
            fi
        } || {
            echo "Grani failed at integrationSuccess call" &>> $LOG
            exit 20;
        }
    else
        echo "ERROR : Wrong STATE argument (analysis, integration)" &>> $LOG
        exit 1;
    fi
else
    echo "INFO : The value 'KDI' is 'no' ($KDI) then there is no integration step" &>> $LOG
fi
