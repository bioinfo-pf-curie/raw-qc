# Raw-QC 

**Institut Curie - Nextflow raw-qc analysis pipeline**

[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A50.32.0-brightgreen.svg)](https://www.nextflow.io/)
[![MultiQC](https://img.shields.io/badge/MultiQC-1.8-blue.svg)](https://multiqc.info/)
[![Install with](https://anaconda.org/anaconda/conda-build/badges/installer/conda.svg)](https://conda.anaconda.org/anaconda)
[![Singularity Container available](https://img.shields.io/badge/singularity-available-7E4C74.svg)](https://singularity.lbl.gov/)
[![Docker Container available](https://img.shields.io/badge/docker-available-003399.svg)](https://www.docker.com/)


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
4. Run first mapping screen on know references and sources of contamination ([`fastq Screen`](https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/))
5. Present all QC results in a final report ([`MultiQC`](http://multiqc.info/))

### Quick help

```bash
N E X T F L O W  ~  version 19.04.0
Launching `main.nf` [cheesy_fermi] - revision: 8038a4770c
raw-qc v1.2.0
=======================================================
	
Usage:
nextflow run main.nf --reads '*_R{1,2}.fastq.gz' -profile conda
nextflow run main.nf --samplePlan sample_plan -profile conda
				
Mandatory arguments:
--reads [file]                Path to input data (must be surrounded with quotes)
--samplePlan [file]           Path to sample plan input file (cannot be used with --reads)
-profile [str]                Configuration profile to use. test / conda / singularity / cluster (see below)
									  
Options:
--singleEnd [bool]            Specifies that the input is single end reads
--trimTool [str]              Specifies adapter trimming tool ['trimgalore', 'atropos', 'fastp']. Default is 'trimgalore'
								  
Trimming options:
--adapter [str]               Type of adapter to trim ['auto', 'truseq', 'nextera', 'smallrna']. Default is 'auto' for automatic detection
--qualTrim [int]              Minimum mapping quality for trimming. Default is '20'
--nTrim [bool]                Trim 'N' bases from either side of the reads
--twoColour [bool]            Trimming for NextSeq/NovaSeq sequencers
--minLen [int]                Minimum length of trimmed sequences. Default is '10'
																						
Presets:
--picoV1 [bool]               Sets version 1 for the SMARTer Stranded Total RNA-Seq Kit - Pico Input kit. Only for trimgalore and fastp
--picoV2 [bool]               Sets version 2 for the SMARTer Stranded Total RNA-Seq Kit - Pico Input kit. Only for trimgalore and fastp
--rnaLig [bool]               Sets trimming setting for the stranded mRNA prep Ligation-Illumina. Only for trimgalore and fastp.
--polyA [bool]                Sets trimming setting for 3-seq analysis with polyA tail detection
																													
Other options:
--outDir [dir]                The output directory where the results will be saved
-name [str]                   Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic
--metadata [file]             Add metadata file for multiQC report
																																		  
Skip options:
--skipFastqcRaw [bool]        Skip FastQC on raw sequencing reads
--skipTrimming [bool]         Skip trimming step
--skipFastqcTrim [bool]       Skip FastQC on trimmed sequencing reads
--skipFastqSreeen [bool]      Skip FastQScreen on trimmed sequencing reads
--skipMultiqc [bool]          Skip MultiQC step
																																											
=======================================================
Available Profiles
-profile test                 Run the test dataset
-profile conda                Build a new conda environment before running the pipeline. Use `--condaCacheDir` to define the conda cache path
-profile multiconda           Build a new conda environment per process before running the pipeline. Use `--condaCacheDir` to define the conda cache path
-profile path                 Use the installation path defined for all tools. Use `--globalPath` to define the insallation path
-profile multipath            Use the installation paths defined for each tool. Use `--globalPath` to define the insallation path
-profile docker               Use the Docker images for each process
-profile singularity          Use the Singularity images for each process. Use `--singularityPath` to define the insallation path
-profile cluster              Run the workflow on the cluster, instead of locally

```

### Quick run

The pipeline can be run on any infrastructure from a list of input files or from a sample plan as follow

#### Run the pipeline on the test dataset
See the conf/test.conf to set your test dataset.

```
nextflow run main.nf -profile conda,test --genomeAnnotationPaths 'ANNOTATION_FOLDER'

```

#### Run the pipeline from a sample plan

```
nextflow run main.nf --samplePlan MY_SAMPLE_PLAN --outDir MY_OUTPUT_DIR -profile conda --genomeAnnotationPaths 'ANNOTATION_FOLDER'

```

#### Run the pipeline on a cluster

```
echo "nextflow run main.nf --reads '*.R{1,2}.fastq.gz' --outDir MY_OUTPUT_DIR -profile singularity,cluster" | qsub -N rawqc

```

### Defining the '-profile'

By default (whithout any profile), Nextflow will excute the pipeline locally, expecting that all tools are available from your `PATH` variable.

In addition, we set up a few profiles that should allow you i/ to use containers instead of local installation, ii/ to run the pipeline on a cluster instead of on a local architecture.
The description of each profile is available on the help message (see above).

Here are a few examples of how to set the profile option. See the [full documentation](docs/profiles.md) for details.

```
## Run the pipeline locally, using the paths defined in the configuration for each tool (see conf/path.config)
-profile path --globalPath INSTALLATION_PATH 

## Run the pipeline on the cluster, using the Singularity containers
-profile cluster,singularity --singularityPath SINGULARITY_PATH 

## Run the pipeline on the cluster, building a new conda environment
-profile cluster,conda --condaCacheDir CONDA_CACHE 
```

### Sample Plan

A sample plan is a csv file (comma separated) that list all samples with their biological IDs, **with no header**.


SAMPLE_ID | SAMPLE_NAME | PATH_TO_R1_FASTQ | [PATH_TO_R2_FASTQ]

### Full Documentation

1. [Installation](docs/installation.md)
2. [Reference genomes](docs/referenceGenomes.md)
3. [Running the pipeline](docs/usage.md)
4. [Output and how to interpret the results](docs/output.md)
5. [Troubleshooting](docs/troubleshooting.md)

### Credits

This pipeline has been set up and written by the sequencing facility and the bioinformatics platform of the Institut Curie (T. Alaeitabar, D. Desvillechabrol, S. Baulande, N. Servant)

### Contacts

For any question, bug or suggestion, please, contact the bioinformatics core facility.


