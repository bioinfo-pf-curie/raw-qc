# Raw-QC 

**Institut Curie - Nextflow raw-qc analysis pipeline**

[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A50.32.0-brightgreen.svg)](https://www.nextflow.io/)
[![MultiQC](https://img.shields.io/badge/MultiQC-1.8-blue.svg)](https://multiqc.info/)
[![Install with](https://anaconda.org/anaconda/conda-build/badges/installer/conda.svg)](https://conda.anaconda.org/anaconda)
[![Singularity Container available](https://img.shields.io/badge/singularity-available-7E4C74.svg)](https://singularity.lbl.gov/)

### Introduction

The main goal of the `raw-qc` pipeline is to perform quality controls on raw sequencing reads, regardless the sequencing application.
It was designed to help sequencing facilities to validate the quality of the generated data.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. 
It comes with docker / singularity containers making installation trivial and results highly reproducible.

### Short comparison of trimming tools

By default, `raw-qc` is using `TrimGalore!` for quality and adapters trimming, but other tools are also available.

|                      | TrimGalore |  Fastp   | Atropos  |
|----------------------|------------|----------|----------|
| pico protocol        |  &#x2611;  | &#x2611; |          | 
| 3'seq protocol       |  &#x2611;  |          | &#x2611; |
| 2-colour support     |  &#x2611;  | &#x2611; | &#x2611; |
| Min adapter overlap  |  &#x2611;  |          | &#x2611; |
| Adapter detection    |  +++       | ++       | -        |
| Poly N trimming      |  &#x2611;  |          | &#x2611; |
| Speed                |  ++        | +++      | +        |


**/!\ Because of serval issues found in the auto-detection mode of the Atropos software, the `detect` command has been removed from the pipeline. 
It means that Atropos currently requires the specification of the adapter to remove (`--adapter`) to be used.**


### Pipline summary

1. Run quality control of raw sequencing reads ([`fastqc`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
2. Trim sequencing adapters ([`TrimGalore!`](https://github.com/FelixKrueger/TrimGalore) / [`fastp`](https://github.com/OpenGene/fastp) / [`Atropos`](http://gensoft.pasteur.fr/docs/atropos/1.1.18/guide.html))
3. Run quality control of trimmed sequencing reads ([`fastqc`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
4. Present all QC results in a final report ([`MultiQC`](http://multiqc.info/))


### Quick help

```bash
N E X T F L O W  ~  version 19.04.0
Launching `main.nf` [cheesy_fermi] - revision: 8038a4770c
raw-qc v1.0dev
=======================================================

Usage:
nextflow run main.nf --reads '*_R{1,2}.fastq.gz' -profile conda
nextflow run main.nf --samplePlan sample_plan -profile conda

Mandatory arguments:
  --reads 'READS'               Path to input data (must be surrounded with quotes)
  --samplePlan 'SAMPLEPLAN'     Path to sample plan input file (cannot be used with --reads)
  -profile PROFILE              Configuration profile to use. test / conda / singularity / cluster (see below)

Options:
  --singleEnd                   Specifies that the input is single end reads
  --trimtool 'TOOL'             Specifies adapter trimming tool ['trimgalore', 'atropos', 'fastp']. Default is 'trimgalore'

Trimming options:
  --adapter 'ADAPTER'           Type of adapter to trim ['auto', 'truseq', 'nextera', 'smallrna']. Default is 'auto' for automatic detection
  --qualtrim QUAL               Minimum mapping quality for trimming. Default is '20'
  --ntrim                       Trim 'N' bases from either side of the reads
  --two_colour                  Trimming for NextSeq/NovaSeq sequencers
  --minlen LEN                  Minimum length of trimmed sequences. Default is '10'

Presets:
  --pico_v1                     Sets version 1 for the SMARTer Stranded Total RNA-Seq Kit - Pico Input kit. Only for trimgalore and fastp
  --pico_v2                     Sets version 2 for the SMARTer Stranded Total RNA-Seq Kit - Pico Input kit. Only for trimgalore and fastp
  --polyA                       Sets trimming setting for 3-seq analysis with polyA tail detection

Other options:
  --outdir 'PATH'               The output directory where the results will be saved
  -name 'NAME'                  Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic
  --metadata 'FILE'             Add metadata file for multiQC report

Skip options:
  --skip_fastqc_raw             Skip FastQC on raw sequencing reads
  --skip_trimming               Skip trimming step
  --skip_fastqc_trim            Skip FastQC on trimmed sequencing reads
  --skip_multiqc                Skip MultiQC step

=======================================================
Available Profiles

  -profile test                 Set up the test dataset
  -profile conda                Build a new conda environment before running the pipeline
  -profile toolsPath            Use the paths defined in configuration for each tool
  -profile singularity          Use the Singularity images for each process
  -profile cluster              Run the workflow on the cluster, instead of locally

```

### Quick run

The pipeline can be run on any infrastructure from a list of input files or from a sample plan as follow

#### Run the pipeline on the test dataset
See the conf/test.conf to set your test dataset.

```
nextflow run main.nf -profile conda,test

```

#### Run the pipeline from a sample plan

```
nextflow run main.nf --samplePlan MY_SAMPLE_PLAN --outdir MY_OUTPUT_DIR -profile conda

```

#### Run the pipeline on a cluster

```
echo "nextflow run main.nf --reads '*.R{1,2}.fastq.gz' --outdir MY_OUTPUT_DIR -profile singularity,cluster" | qsub -N rawqc

```

### Documentation

1. [Installation](docs/installation.md)
2. [Running the pipeline](docs/usage.md)
3. [Output and how to interpret the results](docs/output.md)
4. [Troubleshooting](docs/troubleshooting.md)


### Credits

This pipeline has been set up and written by the sequencing facility and the bioinformatics platform of the Institut Curie (T. Alaeitabar, S. Baulande, N. Servant)

### Contacts

For any question, bug or suggestion, please, contact the bioinformatics core facility.


