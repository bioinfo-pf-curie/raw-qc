Raw-QC Pipeline - Deploy procedure
<br/>#Update date : 02/02/2018

1) Positionnement dans le répertoire local du pipeline (là où se trouve le script deploy)

2) Récupération du commitID qu'on veut déployer:
<br/>git branch -vv

#### Déploiement:
<br/>env={ENV}
<br/>./deploy.sh -e $env -t {commitID}
