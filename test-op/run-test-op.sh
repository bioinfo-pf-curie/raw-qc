#!/bin/bash

### Script pour le test opérationnel du pipeline SAFIR_ALL
### -> ce script pourra être lancé quotidiennement par jenkins pour contrôler la prod
### -> ce script pourra aussi être lancé via gitlab-ci lors des déploiement en dev, valid ou prod (d'où la nécessité d'avoir l'option -e)
### L'objectif de ce script est de pouvoir être lancé pour le pipeline de dev, valid ou prod
### Le dataset de référence se trouve quand à lui en dans kdi_prod. Ce qui pose la question de vérifier que jenkins et gitlab-ci auront bien les droits en lecture sur le dataset de référence



### usage function
function usage {
    echo -e "\nUsage: $(basename "$1") [Options]"
    echo -e "\n [Options]" 
    echo -e "\t-e : environnement used to launch the operational test (either dev, valid or prod)"
    echo -e "\n\n [Example]: \n\t# ./run-test-op.sh -e prod"
}

### function to check that option takes correct values
function check_option_env {
    case "$1"
    in
	dev|valid|prod)
	    true
	    ;;
	*)
	    echo "[ERROR] $1 is not a correct value for the environnement. Use either dev, valid or prod."
	    exit 1
	    ;;
	esac
}

### check if option are correctly passed to the script

while getopts :e:h: option
do
    case "${option}"
    in
        e) ENV=${OPTARG};;
        h) usage "$0" ;  exit 1;;
        \?)  echo "Invalid option: -$OPTARG"; usage "$0"  ;  exit 1;;
	:)  echo "Option -$OPTARG requires an argument." >&2  ; exit 1 ;;
    esac
    shift $((OPTIND-1)); OPTIND=1
done

declare -A REQUIRED_ARGS=( [ENV]="Environnement (either dev, valid or prod) is missing. Use option -e." )

for REQ in "${!REQUIRED_ARGS[@]}"
do
    if [[ -z  ${!REQ} ]]
    then echo -e "\nERROR: ${REQUIRED_ARGS[$REQ]}"
	 usage "$0"
	 exit 1
    fi
done

### check that the options take expected values
check_option_env "$ENV"


### configuration de l'environnement bash pour sortie du script en cas d'erreur
set -o pipefail
set -x
set -u
set -e

## source des varables d'environnement du pipeline
source "/bioinfo/pipelines/safir_all/$ENV/pipeline.conf"

### variables de configuration
RUN="A808"
OUTPUT_TEST=/data/tmp_app/pipelines/rawqc/$ENV/RAW-QC_test-op

PROJECT=$PIPELINE_NAME
DIR_PIPELINE="$pipeline_path/$ENV/"
#DIR_TMP="$ngs_run_temp_diag/$ENV"
DIR_LOG="$DIR_TMP"/"$PROJECT"/"$RUN"/"$(date +"%Y-%m-%d_%H:%M:%S,%3N")"_"$RANDOM"


timeStampStart=$(date +%s)

date="$(date +"%d-%m-%y")"
DATASET_REF="2004695"
GAINGROUP=w-ngsdm-g`echo ${ENV:0:1}`

rm -rf ${OUTPUT_TEST}/RAW-QC-$RUN

PIPELINE_PATH=/bioinfo/pipelines/rawqc/$ENV
ILLUMINA_DIR=171206_SN7001339_0808_AH3J55BCX2
SEQUENCER=hiseq
KDI_PROJECT=TEST_OP_NGS
PROJECT_TYPE=monoproject
SCOPE=research
DEMAND=NGS17-1118
DATATYPE=PE
CONDA_PATH=$PIPELINE_PATH/.conda/envs/raw-qc/bin/
OUTPUT_PATH=/data/tmp_app/pipelines/rawqc/$ENV/
RIMS_ID=

echo "$PIPELINE_PATH/raw-qc_snakemake/raw-qc_workflow_launcher.sh -c $PIPELINE_PATH/raw-qc_snakemake/raw-qc_workflow.conf -r $RUN -e $ENV -i $ILLUMINA_DIR -s $SEQUENCER -k $KDI_PROJECT -t $PROJECT_TYPE -o $SCOPE -m $DEMAND -y $DATATYPE -a $CONDA_PATH -f $OUTPUT_PATH -u no -d" | qsub -q batch -N rawqc_master_Test-op -d $OUTPUT_PATH -l nodes=1:ppn=1,mem=1Gb

## Attendre fin de l'analyse
ANALYSIS_FINISHED="False"

if [[ -e ${OUTPUT_TEST}/RAW-QC-$RUN/kdi_export_rule_ok.txt ]];then

    ANALYSIS_FINISHED="True"
    DATASET_CURRENT=$(cat ${OUTPUT_TEST}/RAW-QC-$RUN/kdi_create_dataset_rule_ok.txt)

else

    while [ $ANALYSIS_FINISHED != "True" ]
    do
        sleep 10

        timeStampCheck=$(date +%s)
        timeStampDiff=$(($timeStampCheck-$timeStampStart))

        if [ $timeStampDiff -gt "86400" ];then
            exit 1
        fi

        if [[ -e ${OUTPUT_TEST}/RAW-QC-$RUN/kdi_export_rule_ok.txt ]];then
            ANALYSIS_FINISHED="True"
            DATASET_CURRENT=$(cat ${OUTPUT_TEST}/RAW-QC-$RUN/kdi_create_dataset_rule_ok.txt)
        else
            ANALYSIS_FINISHED="False"
        fi
    done
fi

sleep 60


if [[ -z $DATASET_CURRENT ]]
then
    echo '$DATASET_CURRENT' is empty > ${OUTPUT_TEST}/${RUN}-FunctionalTest-${date}.results
    exit 1
fi

if ! [[ $DATASET_CURRENT =~ ^[0-9]+$ ]]
then
    echo '$DATASET_CURRENT' is not a number > ${OUTPUT_TEST}/${RUN}-FunctionalTest-${date}.results
    exit 1
fi

echo "Date: $date" > ${OUTPUT_TEST}/${RUN}-FunctionalTest-${date}.results
echo "Dataset id: $DATASET_CURRENT" >> ${OUTPUT_TEST}/${RUN}-FunctionalTest-${date}.results


## Vérification de l'analyse et comparaison au dataset de référence

cd /data/kdi_prod/dataset_all/$DATASET_REF/

for i in $(find archive/ -type f); do if ! echo $i | grep -q -E "Log_Torque|Logs"; then echo "File to compare: $i"; diff -a /data/kdi_prod/dataset_all/$DATASET_REF/$i /data/kdi_$ENV/dataset_all/$DATASET_CURRENT/$i; fi; done > ${OUTPUT_TEST}/test_archive.txt

#for i in $(find nobackup/ -type f); do if ! echo $i | grep -q -E "Log_Torque|Logs"; then echo "File to compare: $i"; diff -a /data/kdi_$ENV/dataset_all/$DATASET_REF/$i /data/kdi_$ENV/dataset_all/$DATASET_CURRENT/$i; fi; done > ${OUTPUT_TEST}/test_nobackup.txt

for i in $(find backup/ -type f ! \( -iname '*\.log\.*' -o -iname '*\.conf\.*' -o -iname '*\.config\.*' -o -iname '*.xlsx' -o -iname '*_input_file.csv' -o -iname '*.pdf' -o -iname '*_list.txt' \)); do if ! echo $i | grep -q -E "Log_Torque|Logs"; then echo "File to compare: $i"; diff <( grep -Ev "^##fileDate=|##source=" /data/kdi_prod/dataset_all/$DATASET_REF/$i) <( grep -Ev "^##fileDate=|##source=" /data/kdi_$ENV/dataset_all/$DATASET_CURRENT/$i); fi; done > ${OUTPUT_TEST}/test_backup.txt

find export/user/ -type l > ${OUTPUT_TEST}/test_export_ref.txt

cd /data/kdi_$ENV/dataset_all/$DATASET_CURRENT/
find export/user/ -type l > ${OUTPUT_TEST}/test_export_current.txt

diff ${OUTPUT_TEST}/test_export_ref.txt ${OUTPUT_TEST}/test_export_current.txt > ${OUTPUT_TEST}/test_export.txt

echo -e "test_archive: \n" >> ${OUTPUT_TEST}/${RUN}-FunctionalTest-${date}.results
cat ${OUTPUT_TEST}/test_archive.txt >> ${OUTPUT_TEST}/${RUN}-FunctionalTest-${date}.results
echo -e "\n\ntest_backup: \n" >> ${OUTPUT_TEST}/${RUN}-FunctionalTest-${date}.results
cat ${OUTPUT_TEST}/test_backup.txt >> ${OUTPUT_TEST}/${RUN}-FunctionalTest-${date}.results
echo -e "\n\ntest_export: \n" >> ${OUTPUT_TEST}/${RUN}-FunctionalTest-${date}.results
cat ${OUTPUT_TEST}/test_export.txt >> ${OUTPUT_TEST}/${RUN}-FunctionalTest-${date}.results

sed '/^File\ to\ compare:/d' ${OUTPUT_TEST}/test_archive.txt > ${OUTPUT_TEST}/test_archive_diff.txt
sed '/^File\ to\ compare:/d' ${OUTPUT_TEST}/test_backup.txt > ${OUTPUT_TEST}/test_backup_diff.txt
sed '/^File\ to\ compare:/d' ${OUTPUT_TEST}/test_export.txt > ${OUTPUT_TEST}/test_export_diff.txt

if [ -s ${OUTPUT_TEST}/test_archive_diff.txt ] || [ -s ${OUTPUT_TEST}/test_backup_diff.txt ] || [ -s ${OUTPUT_TEST}/test_export_diff.txt ];then
    echo "Test Failed! " >> ${OUTPUT_TEST}/${RUN}-FunctionalTest-${date}.results
    exit 1
else
    echo "It works ! " >> ${OUTPUT_TEST}/${RUN}-FunctionalTest-${date}.results
fi


