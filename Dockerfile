FROM nfcore/base
LABEL authors="me" \
      description="Docker image containing all requirements for nf-core/mypipeline pipeline"

COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/nf-core-mypipeline-1.0dev/bin:$PATH
