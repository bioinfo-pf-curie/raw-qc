#!/bin/bash

### Script de déploiement du pipeline

### usage function
function usage {
    echo -e "\nUsage: $(basename "$1") [Options]"
    echo -e "\n [Options]"
    echo -e "\t-e : environnement used to launch the operational test (either dev, valid or prod)"
    echo -e "\t-t : git tag to deploy (can be a tag or commit id)"
    echo -e "\n\n [Example]: \n\t# ./deploy.sh -e dev -t v1.2.3"
}


### check if option are correctly passed to the script

while getopts :e:t:h: option
do
    case "${option}"
    in
        e) env=${OPTARG};;
	      t) tag=${OPTARG};;
        h) usage "$0" ;  exit 0;;
        \?)  echo "Invalid option: -$OPTARG"; usage "$0"  ;  exit 1;;
	      :)  echo "Option -$OPTARG requires an argument." >&2  ; exit 1 ;;
    esac
    shift $((OPTIND-1)); OPTIND=1
done

declare -A REQUIRED_ARGS=( [env]="Environnement (either dev, valid or prod) is missing. Use option -e." [tag]=" git tag to deploy  is missing. Use option -t." )

for REQ in "${!REQUIRED_ARGS[@]}"
do
    if [[ -z  ${!REQ} ]]
    then echo -e "\nERROR: ${REQUIRED_ARGS[$REQ]}"
	 usage "$0"
	 exit 1
    fi
done


### configuration de l'environnement bash pour sortie du script en cas d'erreur
### source du bashrc_bioinfo
source "/bioinfo/pipelines/dm-toolbox/prod/bashrc/bashrc_bioinfo"

source pipeline.conf

$deploy_exec -c pipeline.conf -e $env -u $USER -t $tag

### remplacement du nom de version dans le preconf
#post_install_cmd="export PKEY=\$HOME/../deploy_key && export GIT_SSH=/bioinfo/pipelines/git_deploy.sh && sed -i -e "s/^VERSION=.*/VERSION=$tag/" "$preconf_file" "


#echo $post_install_cmd | $vault_exec ssh -role ssh_"$pipeline_group"_"${env:0:1}" -mount-point sshapp -strict-host-key-checking=no w-"$pipeline_group"-u"${env:0:1}"@vpipelines.service.soa.curie.fr

echo "cp -r /bioinfo/pipelines/ngsdm/dev/Procedures/conda ." | $vault_exec ssh -role ssh_"$pipeline_group"_"${env:0:1}" -mount-point sshapp -strict-host-key-checking=no w-"$pipeline_group"-u"${env:0:1}"@vpipelines.service.soa.curie.fr
