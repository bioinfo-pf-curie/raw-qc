Raw-QC Pipeline - Deploy procedure
<br/>#Update date : 02/02/2018

1) Positionnement dans le répertoire local du pipeline (là où se trouve le script deploy)


2) Récupération du commitID qu'on veut déployer:
<br/>git branch -vv

#### Déploiement:
<br/>env={ENV}
<br/>./deploy.sh -e $env -t {commitID}


3) (Temporairement) Installation du conda dans l'environnement où on veut déployer le pipeline:

#### Connexion en gainuser

<br/>env={ENV}
<br/>export VAULT_ADDR=https://vault.curie.fr
<br/>/bioinfo/local/bin/vault  auth -method=ldap -path=ldapnet username={ckamoun,ddesvill,glucotte}
<br/>vault write -field=signed_key calcsub/sign/rawqc__$env public_key=@$HOME/.ssh/id_rsa.pub > $HOME/.ssh/id_rsa-cert.pub
<br/>ssh w-rawqc-u${env:0:1}@calcsub


#### Installation du conda avec autotropose temporairement dans /bioinfo/pipelines/ngsdm/dev/Procedures/

<br/>/bioinfo/local/build/Centos/miniconda/miniconda3/bin/conda config --add channels conda-forge
<br/>/bioinfo/local/build/Centos/miniconda/miniconda3/bin/conda config --add channels bioconda
<br/>/bioinfo/local/build/Centos/miniconda/miniconda3/bin/conda create --name raw-qc --file requirements.txt
<br/>source activate raw-qc
<br/>export PATH=/bioinfo/local/build/Centos/miniconda/miniconda3/bin:$PATH
<br/>source activate raw-qc
<br/>cd /bioinfo/pipelines/ngsdm/dev/Procedures/autotropos
<br/>python setup.py install
<br/>source deactivate
