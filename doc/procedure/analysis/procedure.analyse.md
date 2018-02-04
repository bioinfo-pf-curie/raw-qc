Raw-QC Pipeline - Launching procedure
<br/>#Update date : 02/02/2018


#### Connexion à calcsub avec le gainuser pour lancer et suivre les jobs des pipelines Raw-QC

env=prod
<br/>export VAULT_ADDR=https://vault.curie.fr
<br/>/bioinfo/local/bin/vault  auth -method=ldap -path=ldapnet username={ckamoun, glucotte}
<br/>vault write -field=signed_key calcsub/sign/rawqc__$env public_key=@$HOME/.ssh/id_rsa.pub > $HOME/.ssh/id_rsa-cert.pub
<br/>ssh w-rawqc-u${env:0:1}@calcsub


#### Lancement de l'analyse

1)
<br/>env=prod
<br/>RUN={RUN}
<br/>PIPELINE_PATH=/bioinfo/pipelines/rawqc/$env
<br/>ILLUMINA_DIR={ILLUMINA_DIR}
<br/>SEQUENCER={hiseq/miseq/nextseq/miseq_zebulon}
<br/>KDI_PROJECT={KDI_PROJECT}
<br/>PROJECT_TYPE={multiproject/monoproject}
<br/>SCOPE={diag/research}
<br/>DEMAND={RIMS_ID}
<br/>DATATYPE={SE/PE}
<br/>CONDA_PATH=$PIPELINE_PATH/.conda/envs/raw-qc/bin/
<br/>OUTPUT_PATH=/data/tmp_app/pipelines/rawqc/$env/
<br/>RIMS_ID={laisser vide en manuel}

<br/>echo "$PIPELINE_PATH/raw-qc_snakemake/raw-qc_workflow_launcher.sh -c $PIPELINE_PATH/raw-qc_snakemake/raw-qc_workflow.conf -r $RUN -e $env -i $ILLUMINA_DIR -s $SEQUENCER -k $KDI_PROJECT -t $PROJECT_TYPE -o $SCOPE -m $DEMAND -y $DATATYPE -a $CONDA_PATH -f $OUTPUT_PATH -u no -d $RIMS_ID" | qsub -q batch -N rawqc_master -d $OUTPUT_PATH -l nodes=1:ppn=1,mem=1Gb

#### Si une erreur est survenue et le job rawqc_master tourne toujours:

1)
<br/>qdel {jobID}
<br/>env=prod
<br/>RUN={RUN}
<br/>PIPELINE_PATH=/bioinfo/pipelines/rawqc/$env
<br/>ILLUMINA_DIR={ILLUMINA_DIR}
<br/>SEQUENCER={hiseq/miseq/nextseq/miseq_zebulon}
<br/>KDI_PROJECT={KDI_PROJECT}
<br/>PROJECT_TYPE={multiproject/monoproject}
<br/>SCOPE={diag/research}
<br/>DEMAND={RIMS_ID}
<br/>DATATYPE={SE/PE}
<br/>CONDA_PATH=$PIPELINE_PATH/.conda/envs/raw-qc/bin/
<br/>OUTPUT_PATH=/data/tmp_app/pipelines/rawqc/$env/
<br/>RIMS_ID={laisser vide en manuel}

<br/>echo "$PIPELINE_PATH/raw-qc_snakemake/raw-qc_workflow_launcher.sh -c $PIPELINE_PATH/raw-qc_snakemake/raw-qc_workflow.conf -r $RUN -e $env -i $ILLUMINA_DIR -s $SEQUENCER -k $KDI_PROJECT -t $PROJECT_TYPE -o $SCOPE -m $DEMAND -y $DATATYPE -a $CONDA_PATH -f $OUTPUT_PATH -u yes -d $RIMS_ID" | qsub -q batch -N rawqc_master -d $OUTPUT_PATH -l nodes=1:ppn=1,mem=1Gb

2)
<br/>echo "$PIPELINE_PATH/raw-qc_snakemake/raw-qc_workflow_launcher.sh -c $PIPELINE_PATH/raw-qc_snakemake/raw-qc_workflow.conf -r $RUN -e $env -i $ILLUMINA_DIR -s $SEQUENCER -k $KDI_PROJECT -t $PROJECT_TYPE -o $SCOPE -m $DEMAND -y $DATATYPE -a $CONDA_PATH -f $OUTPUT_PATH -u no -d $RIMS_ID" | qsub -q batch -N rawqc_master -d $OUTPUT_PATH -l nodes=1:ppn=1,mem=1Gb

#### Si une erreur est survenue et plus aucun job rawqc de ce run ne tourne:

env=prod
<br/>RUN={RUN}
<br/>PIPELINE_PATH=/bioinfo/pipelines/rawqc/$env
<br/>ILLUMINA_DIR={ILLUMINA_DIR}
<br/>SEQUENCER={hiseq/miseq/nextseq/miseq_zebulon}
<br/>KDI_PROJECT={KDI_PROJECT}
<br/>PROJECT_TYPE={multiproject/monoproject}
<br/>SCOPE={diag/research}
<br/>DEMAND={RIMS_ID}
<br/>DATATYPE={SE/PE}
<br/>CONDA_PATH=$PIPELINE_PATH/.conda/envs/raw-qc/bin/
<br/>OUTPUT_PATH=/data/tmp_app/pipelines/rawqc/$env/
<br/>RIMS_ID={laisser vide en manuel}

<br/>echo "$PIPELINE_PATH/raw-qc_snakemake/raw-qc_workflow_launcher.sh -c $PIPELINE_PATH/raw-qc_snakemake/raw-qc_workflow.conf -r $RUN -e $env -i $ILLUMINA_DIR -s $SEQUENCER -k $KDI_PROJECT -t $PROJECT_TYPE -o $SCOPE -m $DEMAND -y $DATATYPE -a $CONDA_PATH -f $OUTPUT_PATH -u no -d $RIMS_ID" | qsub -q batch -N rawqc_master -d  -l nodes=1:ppn=1,mem=1Gb



