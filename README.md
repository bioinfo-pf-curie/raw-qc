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

### 3'/5' adapter Trimming

Several steps of trimming can be performed accord to the specified options.

1. 3' adapter trimming (with `TrimGalore!` or `fastp`)

The adapters can be automatically detected (default, `--adapter 'auto'`).  
However, one can force the 3' adapter sequence by either specifying the type of library (`truseq`,`nextera`,`smallrna`), 
or by directly specifying the trimming options (`--adapter '-a CTGTCTCTTATACACATCT'`).

In addition, `raw-qc` also provides a few preset for automatic clipping:

| Options                   | single-end                     | paired-end                               |
|---------------------------|--------------------------------|------------------------------------------|
| pico version2 (--picoV2)  |                                | R1: clip 3bp in 3' / R2: clip 3bp in 5'  |
| RNA ligation (--rnaLig)   | R1: clip 1bp in 5' + 2bp in 3' | R1/R2 :  clip 1bp in 5' + 2bp in 3'      |

Additional available options:

* `--nTrim` - trim N at both read ends
* `--twoColour` - for two colours sequencing technologies (Novaseq/Nextseq)
* `--qualTrim` - Minimum base quality (default 20)
* `--minLen` - Minimum read size (default 10)

2. 5' adapter (linkers)

In addition to 3' end adapter, some protocols can require linkers (such as TSO) which has to be removed from the 5' end of reads.  
The `cutadapt` can be defined directly using `--adapter5` option, or the following preset

| Options                   | single-end                     | paired-end                                                  |
|---------------------------|--------------------------------|-------------------------------------------------------------|
| smartSeqV4                | '-g AAGCAGTGGTATCAACGCAGAGTAC' | '-g AAGCAGTGGTATCAACGCAGAGTAC -G AAGCAGTGGTATCAACGCAGAGTAC' |


3. PolyA trimming

Finally, for RNA-seq data, it can usually be useful to trim for polyA tail.  
This step can specified using the option `--polyA`.


### Pipline summary

1. Run quality control of raw sequencing reads ([`fastqc`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
2. Trim sequencing adapters ([`TrimGalore!`](https://github.com/FelixKrueger/TrimGalore) / [`fastp`](https://github.com/OpenGene/fastp)
3. Run quality control of trimmed sequencing reads ([`fastqc`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
4. Run first mapping screen on know references and sources of contamination ([`fastq Screen`](https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/))
5. Separate host/graft reads for PDX model ([`xengsort`](https://gitlab.com/genomeinformatics/xengsort))
6. Present all QC results in a final report ([`MultiQC`](http://multiqc.info/))

### Quick help

```bash
N E X T F L O W  ~  version 21.10.6
Launching `main.nf` [distracted_curie] - revision: dc75952132
------------------------------------------------------------------------

  ______                      _____ _____ 
  | ___ \                    |  _  /  __ \
  | |_/ /__ ___      ________| | | | /  \/
  |    // _` \ \ /\ / /______| | | | |    
  | |\ \ (_| |\ V  V /       \ \/' / \__/\
  \_| \_\__,_| \_/\_/         \_/\_\\____/
			

                v3.0.0
------------------------------------------------------------------------
							   
							   
Usage:
								   
The typical command for running the pipeline is as follows:
									   
nextflow run main.nf --reads PATH --samplePlan PATH --profile STRING
										   
MANDATORY ARGUMENTS:
   --profile    STRING [conda, cluster, docker, multiconda, conda, path, multipath, singularity]  Configuration profile to use. Can use multiple (comma separated).
   --reads      PATH                                                                              Path to input data (must be surrounded with quotes)
   --samplePlan PATH                                                                              Path to sample plan (csv format) with raw reads (if `--reads` is not specified)

INPUTS:
    --singleEnd           For single-end input data
	
TRIMMING:
	--adapter   STRING [auto, truseg, nextera, smallrna, *]   Type of 3' adapter to trim
	--adapter5  STRING                                        Specified cutadapt options for 5' adapter trimming
	--minLen    INTEGER                                       Minimum length of trimmed sequences
	--nTrim                                                   Trim poly-N sequence at the end of the reads
	--qualTrim  INTEGER                                       Minimum mapping quality for trimming
	--tooColour                                               Trimming for NextSeq/NovaSeq sequencers
	--trimTool  STRING [trimgalore, fastp]                    Tool for 3' adapter trimming and auto-detection

PRESET:
	--picoV2               Preset of clipping parameters for picoV2 protocol
	--polyA                Preset for polyA tail trimming
	--rnaLig               Preset for RNA ligation protocol
	--smartSeqV4           Preset for smartSeqV4 RNA-seq protocol

REFERENCES:
	--genomeAnnotationPath PATH   Path to genome annotations folder

SKIP OPTIONS:
	--skipFastqcRaw              Disable FastQC
	--skipFastqcScreen           Disable FastqcScreen
	--skipFastqcTrim             Disable FastQC
	--skipMultiqc                Disable MultiQC
	--skipTrimming               Disable Trimming

OTHER OPTIONS:
	--metadata      PATH     Specify a custom metadata file for MultiQC
	--multiqcConfig PATH     Specify a custom config file for MultiQC
	--name          STRING   Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic
	--outDir        PATH     The output directory where the results will be saved

=======================================================
Available Profiles
  -profile test                        Run the test dataset
  -profile conda                       Build a new conda environment before running the pipeline. Use `--condaCacheDir` to define the conda cache path
  -profile multiconda                  Build a new conda environment per process before running the pipeline. Use `--condaCacheDir` to define the conda cache path
  -profile path                        Use the installation path defined for all tools. Use `--globalPath` to define the insallation path
  -profile multipath                   Use the installation paths defined for each tool. Use `--globalPath` to define the insallation path
  -profile docker                      Use the Docker images for each process
  -profile singularity                 Use the Singularity images for each process. Use `--singularityPath` to define the insallation path
  -profile cluster                     Run the workflow on the cluster, instead of locally
  
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

This pipeline has been set up and written by the sequencing facility and the bioinformatics platform of the Institut Curie (T. Alaeitabar, D. Desvillechabrol, F. Martin, S. Baulande, N. Servant)

### Contacts

For any question, bug or suggestion, please, contact the bioinformatics core facility.


