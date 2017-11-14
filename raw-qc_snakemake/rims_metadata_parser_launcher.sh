#!/bin/bash
### source du bashrc_bioinfo
#source "/bioinfo/pipelines/dm-toolbox/prod/bashrc/bashrc_bioinfo"
#if [[ $? -ne 0 ]]; then echo "Source failed for bashrc_bioinfo: /bioinfo/pipelines/dm-toolbox/prod/bashrc/bashrc_bioinfo"; exit 1; fi

#set +x


while getopts ":o:l:e:r:p:c:d:" option
do
    case "$option" in
    o)    OUTPUT_PATH=$OPTARG;;
    l)    log=$OPTARG;;
    e)    env=$OPTARG;;
    r)    run=$OPTARG;;
    p)    project=$OPTARG;;
    c)    cluster=$OPTARG;;
    d)    demand=$OPTARG;;
    \?)   echo >&2 "Usage: $0 [-o OUTPUT_PATH] [-l LOG_FILE] [-e RIMS_ENV] [-r RUN] [-p PROJECT] [-c CLUSTER] [-d DEMAND]"
        exit 1;;
    esac
done

echo "OUTPUT_PATH: $OUTPUT_PATH; LOG_FILE: $log; RIMS_ENV: $env; RUN: $run; CLUSTER: $cluster; PROJECT: $project; DEMAND: $demand;"

if [[ -z $OUTPUT_PATH ]] || [[ -z $log ]] || [[ -z $env ]] || [[ -z $run ]] || [[ -z $cluster ]] || [[ -z $project ]] || [[ -z $demand ]]
then
    echo "ERROR : There is/are empty argument(s)"
    exit 1
fi

if [[ ! -d $OUTPUT_PATH ]] && [[ ! -z $OUTPUT_PATH ]]
then
    mkdir -p $OUTPUT_PATH
elif [[ -z $OUTPUT_PATH ]]
then
    echo "ERROR : empty variable OUTPUT_PATH: $OUTPUT_PATH"
    exit 1
fi
if [ "${env,,}" == "dev" ]
then
    export PYTHONPATH="/bioinfo/pipelines/SOAPclient/python/kdi_dev/instance"
    export GAINGROUP="/bioinfo/local/bin/gaingroup -g w-ngsdm-gd"
elif [ "${env,,}" == "valid" ]
then
    export PYTHONPATH="/bioinfo/pipelines/SOAPclient/python/kdi_valid/instance"
    export GAINGROUP="/bioinfo/local/bin/gaingroup -g w-ngsdm-gv"
elif [ "${env,,}" == "prod" ]
then
   export PYTHONPATH="/bioinfo/pipelines/SOAPclient/python/kdi_prod/instance"
   export GAINGROUP="/bioinfo/local/bin/gaingroup -g w-ngsdm-gp"
else
    echo "ERROR : Wrong KDI env argument, must be 'dev', 'valid' or 'prod'"
    exit 1
fi
echo "PYTHONPATH : $PYTHONPATH"

export SCRIPT=$(realpath -s $0)
export SCRIPTPATH=$(dirname $SCRIPT)
echo "RIMS_METADATA_PARSER PATH : $SCRIPTPATH"

if [ ${cluster,,} == "debian" ]
then
    {
    echo "$GAINGROUP /bioinfo/local/build/python/python-2.7.9/bin/python2.7 $SCRIPTPATH/rims_metadata_parser.py -o $OUTPUT_PATH -l $log -e ${env,,} -r $run --demand $demand" &>> $log
    $GAINGROUP /bioinfo/local/build/python/python-2.7.9/bin/python2.7 $SCRIPTPATH/rims_metadata_parser.py -o $OUTPUT_PATH -l $log -e ${env,,} -r $run --demand $demand &>> $log && error_status=$? && echo "Script rims_metadata_parser.py : exit status '$error_status'" &>> $log
    } ||
    {
    error_status=$?
    echo "TECHNICAL ERROR : the rims_metadata_parser script is in error state : the rims_metadata_parser script isn't launched (exit status '$error_status')" &>> $log
    exit $error_status
    }
elif [ ${cluster,,} == "centos" ]
then
    {
    echo "$GAINGROUP /bioinfo/local/build/Centos/python/python-2.7.12/bin/python2.7 $SCRIPTPATH/rims_metadata_parser.py -o $OUTPUT_PATH -l $log -e ${env,,} -r $run --demand $demand" &>> $log
    $GAINGROUP /bioinfo/local/build/Centos/python/python-2.7.12/bin/python2.7 $SCRIPTPATH/rims_metadata_parser.py -o $OUTPUT_PATH -l $log -e ${env,,} -r $run --demand $demand &>> $log && error_status=$? && echo "Script rims_metadata_parser.py : exit status '$error_status'" &>> $log
    } ||
    {
    error_status=$?
    echo "TECHNICAL ERROR : the rims_metadata_parser script is in error state : the rims_metadata_parser script isn't launched (exit status '$error_status')" &>> $log
    exit $error_status
    }
else
    echo "ERROR : Wrong cluster argument" &>> $log
    exit 1
fi
