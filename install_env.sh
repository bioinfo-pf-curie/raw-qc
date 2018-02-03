#!/bin/bash

/bioinfo/local/build/Centos/miniconda/miniconda3/bin/conda config --add channels conda-forge
/bioinfo/local/build/Centos/miniconda/miniconda3/bin/conda config --add channels bioconda
/bioinfo/local/build/Centos/miniconda/miniconda3/bin/conda create --name raw-qc --file requirements.txt
export PATH=/bioinfo/local/build/Centos/miniconda/miniconda3/bin:$PATH
source activate raw-qc
git clone https://gitlab.curie.fr/ddesvill/autotropos.git
cd autotropos
python setup.py install
deactivate
