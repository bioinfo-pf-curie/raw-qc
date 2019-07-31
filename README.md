# Raw-QC 

**Institut Curie - Nextflow raw-qc analysis pipeline**

[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A50.32.0-brightgreen.svg)](https://www.nextflow.io/)
[![MultiQC](https://img.shields.io/badge/MultiQC-1.6-blue.svg)](https://multiqc.info/)
[![Install with](https://anaconda.org/anaconda/conda-build/badges/installer/conda.svg)](https://conda.anaconda.org/anaconda)
[![Singularity Container available](https://img.shields.io/badge/singularity-available-7E4C74.svg)](https://singularity.lbl.gov/)

### Introduction

The main goal of the `raw-qc` pipeline is to perform quality controls on raw sequencing reads, regardless the sequencing application.
It was designed to help sequencing facilities to validate the quality of the generated data.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. 
It comes with docker / singularity containers making installation trivial and results highly reproducible.

The current workflow is based on the nf-core best practice. See the nf-core project from details on [guidelines](https://nf-co.re/).

### Short comparison of trimming tools

By default, `raw-qc` is using `TrimGalore!` for quality and adapters trimming, but other tools are also available.

|                      | TrimGalore |  Fastp   | Atropos  |
|----------------------|------------|----------|----------|
| pico protocol        |  &#x2611;  | &#x2611; |          | 
| 3'seq protocol       |  &#x2611;  |          | &#x2611; |
| 2-colour support     |  &#x2611;  | &#x2611; | &#x2611; |
| Min adapter overlap  |  &#x2611;  |          | &#x2611; |
| Adapter detection    |  +++       | ++       | +        |
| Poly N trimming      |  &#x2611;  |          | &#x2611; |
| Speed                |  ++        | +++      | +        |

### Pipline summary

1. Run quality control of raw sequencing reads ([`fastqc`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
2. Trim sequencing adapters ([`TrimGalore!`](https://github.com/FelixKrueger/TrimGalore) / [`fastp`](https://github.com/OpenGene/fastp) \ [`Atropos`](http://gensoft.pasteur.fr/docs/atropos/1.1.18/guide.html))
1. Run quality control of trimmed sequencing reads ([`fastqc`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))

### Documentation

1. [Installation](docs/installation.md)
2. Pipeline configuration
    * [Local installation](docs/configuration/local.md)
    * [Reference genomes](docs/configuration/reference_genomes.md)  
3. [Running the pipeline](docs/usage.md)
4. [Output and how to interpret the results](docs/output.md)
5. [Troubleshooting](docs/troubleshooting.md)

<!-- TODO nf-core: Add a brief overview of what the pipeline does and how it works -->

### Credits
<!-- TODO add authors -->
