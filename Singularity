From:nfcore/base
Bootstrap:docker

%labels
    MAINTAINER me
    DESCRIPTION Singularity image containing all requirements for the nf-core/mypipeline pipeline
    VERSION 1.0dev

%environment
    PATH=/opt/conda/envs/nf-core-mypipeline-1.0dev/bin:$PATH
    export PATH

%files
    environment.yml /

%post
    /opt/conda/bin/conda env create -f /environment.yml
    /opt/conda/bin/conda clean -a
