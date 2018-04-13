#!/bin/bash
## install_tools_via_conda.sh 
## Tools of raw-qc pipeline
##
## Copyright (c) 2019-2020 Institut Curie
## Author(s): Nicolas Servant, Philippe La Rosa
## Contact: nicolas.servant@curie.fr, philippe.larosa@curie.fr
## This software is distributed without any guarantee under the terms of the BSD-3 licence.
## See the LICENCE file for details
##
##
## usage : bash install_tools_via_conda.sh 2>&1 | tee -a build_tools.log 
##
dir_conda_modules=$1
# exemple : /data/modules/pipelines/rawqc/dev 


if [ $# -eq 0 ]; then
    echo "No path name specified!"
    echo "Run bash install_tools_via_conda.sh -h for help"
    exit 1
fi

if [ $1 == "-h" ]; then
    echo "Utility for local installation tools with conda"
    echo "Usage: install_tools_via_conda.sh [path_installation]"
    echo 
    echo "                  Example: bash install_tools_via_conda.sh ./tools"
    exit 0
fi
### installation conda
### ajout assume conda deja installe 
## Installation des tools via conda dans /data/modules/pipelines/rawqc/dev/conda/envs/curie-rawqc-1.0-dev 
cd ${dir_conda_modules}
conda env create -f environment.yml 2>&1 | tee -a install_tools_via_conda.log 
