# Usage

<!-- TODO - Update with the usage of your pipeline -->

## Table of contents

* [Introduction](#general-nextflow-info)
* [Running the pipeline](#running-the-pipeline)
* [Main arguments](#main-arguments)
    * [`-profile`](#-profile)
    * [`--reads`](#-reads)
    * [`--samplePlan`](#-sampleplan)
	* [`--design`](#--design) 
* [Inputs](#inputs)
    * [`--singleEnd`](#--singleend)
* [Trimming](#trimming)
    * [3' adapter](#3adapter)
	* [5' adapter](#5adapter)
	* [polyA trimming](#polya-trimming)
* [Reference genomes](#reference-genomes)
* [Nextflow profiles](#nextflow-profiles)
* [Job resources](#job-resources)
* [Other command line parameters](#other-command-line-parameters)
    * [`--skip*`](#-skip)
    * [`--metadata`](#-metadata)
    * [`--outDir`](#-outdir)
    * [`-name`](#-name)
    * [`-resume`](#-resume)
    * [`-c`](#-c)
    * [`--maxMemory`](#-maxmemory)
    * [`--maxTime`](#-maxtime)
    * [`--maxCpus`](#-maxcpus)
    * [`--multiqcConfig`](#-multiqcconfig)
* [Profile parameters](#profile-parameters)
    * [`--condaCacheDir`](#-condacachedir)
    * [`--globalPath`](#-globalpath)
    * [`--queue`](#-queue)
    * [`--singularityImagePath`](#-singularityimagepath)

## General Nextflow info

Nextflow handles job submissions on SLURM or other environments, and supervises the job execution. Thus the Nextflow process must run until the pipeline is finished. We recommend that you put the process running in the background through `screen` / `tmux` or similar tool. Alternatively you can run nextflow within a cluster job submitted your job scheduler.

It is recommended to limit the Nextflow Java virtual machines memory. We recommend adding the following line to your environment (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```

## Running the pipeline

The typical command for running the pipeline is as follows:
```bash
nextflow run main.nf --reads '*_R{1,2}.fastq.gz' -profile 'singularity'
```

This will launch the pipeline with the `singularity` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work            # Directory containing the nextflow working files
results         # Finished results (configurable, see below)
.nextflow_log   # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

You can change the output director using the `--outDir/-w` options.

## Main arguments

### `-profile`

Use this option to set the [Nextflow profiles](profiles.md). For example:

```bash
-profile singularity,cluster
```

### `--reads`
Use this to specify the location of your input FastQ files. For example:

```bash
--reads 'path/to/data/sample_*_{1,2}.fastq'
```

Please note the following requirements:

1. The path must be enclosed in quotes
2. The path must have at least one `*` wildcard character
3. When using the pipeline with paired end data, the path must use `{1,2}` notation to specify read pairs

If left unspecified, a default pattern is used: `data/*{1,2}.fastq.gz`


### `--samplePlan`

Use this to specify a `sample plan` file instead of a regular expression to find fastq files. For example :

```bash
--samplePlan 'path/to/data/samplePlan.csv
```

The `sample plan` is a csv file with the following information (and no header) :

```
Sample ID,Sample Name,/path/to/R1/fastq/file,/path/to/R2/fastq/file (for paired-end only)
```

## Inputs

### `--singleEnd`

By default, the pipeline expects paired-end data. If you have single-end data, you need to specify `--singleEnd` on the command line when you launch the pipeline. A normal glob pattern, enclosed 
in quotation marks, can then be used for `--reads`. For example:

```bash
--singleEnd --reads '*.fastq.gz'
```

## Trimming

### 3' adapter

3' adapter trimming can be performed either with `TrimGalore!` or `fastp`.
By default, the adapters are automatically detected (default, `--adapter 'auto'`).  

However, the 3' adapter sequence to trim can be specified by either specifying the type of library (`truseq`,`nextera`,`smallrna`), 
or by directly specifying the trimming options (`--adapter '-a CTGTCTCTTATACACATCT'`).

In addition, `raw-qc` also provides a few preset for automatic clipping:

| Options                   | single-end                     | paired-end                               |
|---------------------------|--------------------------------|------------------------------------------|
| `--picoV2`                |                                | R1: clip 3bp in 3' / R2: clip 3bp in 5'  |
| `--rnaLig`                | R1: clip 1bp in 5' + 2bp in 3' | R1/R2 :  clip 1bp in 5' + 2bp in 3'      |

Additional available options:

* `--nTrim` - trim N at both read ends
* `--twoColour` - for two colours sequencing technologies (Novaseq/Nextseq)
* `--qualTrim` - Minimum base quality (default 20)
* `--minLen` - Minimum read size (default 10)

### 5' adapter

In addition to 3' end adapter, some protocols can require linkers (such as TSO) which has to be removed from the 5' end of reads.  
The `cutadapt` can be defined directly using `--adapter5` option, or the following preset

| Options                   | single-end                     | paired-end                                                  |
|---------------------------|--------------------------------|-------------------------------------------------------------|
| `--smartSeqV4`            | '-g AAGCAGTGGTATCAACGCAGAGTAC -g AAGCAGTGGTATCAACGCAGAGTACGGG' | '-g AAGCAGTGGTATCAACGCAGAGTAC -G AAGCAGTGGTATCAACGCAGAGTAC -g AAGCAGTGGTATCAACGCAGAGTAC -g AAGCAGTGGTATCAACGCAGAGTACGGG' |

### PolyA trimming

Finally, for RNA-seq data, it can also be useful to trim for polyA tail.  

Of note, for `fastp` the polyA trimming is performed using the `--polyX` option.
Otherwise, `cutadapt` is run with the following options:

| Options                   | single-end                     | paired-end                              |
|---------------------------|--------------------------------|-----------------------------------------|
| `--polyA`                 | '-a A{20} -g T{150}'           | '-a A{20} -g T{150} -A A{20} -G T{150}' |


## Reference Genomes
The pipeline config files come bundled with paths to the genomes reference files.
The syntax for this reference configuration is as follows:

```nextflow
params {
  genomes {
    fastqScreenGenomes {
      Human = "/path/to/Human/Homo_sapiens.GRCh38"
      Mouse = "/path/to/Mouse/Mus_musculus.GRCm38"
      Rat = "/path/to/Rat/Rnor_6.0"
      Drosophila = "/path/to/Drosophila/BDGP6"
      Worm = "/path/to/Worm/Caenorhabditis_elegans.WBcel235"
      Yeast = "/path/to/Yeast/Saccharomyces_cerevisiae.R64-1-1"
      Arabidopsis = "/path/to/Arabidopsis/Arabidopsis_thaliana.TAIR10"
      Ecoli = "/path/to/E_coli/Ecoli"
      rRNA = "/path/to/rRNA/GRCm38_rRNA"
      MT = "/path/to/Mitochondria/mitochondria"
      PhiX = "/path/to/PhiX/phi_plus_SNPs"
      Lambda = "/path/to/Lambda/Lambda"
      Vectors = "$/path/to/Vectors/Vectors"
      Adapters = "$/path/to/Adapters/Contaminants"
    }
  }
}
```

## Nextflow profiles

Different Nextflow profiles can be used. See [Profiles](profiles.md) for details.

## Job resources

Each step in the pipeline has a default set of requirements for number of CPUs, memory and time (see the [`conf/process.conf`](../conf/process.config) file). 
For most of the steps in the pipeline, if the job exits with an error code of `143` (exceeded requested resources) it will automatically resubmit with higher requests (2 x original, then 3 x original). If it still fails after three times then the pipeline is stopped.

## Other command line parameters

### `--skip*`

The pipeline is made with a few *skip* options that allow to skip optional steps in the workflow.
The following options can be used:
* `--skipFastqcRaw`
* `--skipTrimming`
* `--skipFastqcTrim`
* `--skipFastqSreeen`
* `--skipMultiqc`
				
### `--metadata`
Specify a two-columns (tab-delimited) metadata file to diplay in the final Multiqc report.

### `--outDir`
The output directory where the results will be saved.

### `-name`
Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.

This is used in the MultiQC report (if not default) and in the summary HTML.

**NB:** Single hyphen (core Nextflow option)

### `-resume`
Specify this when restarting a pipeline. Nextflow will used cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously.

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

**NB:** Single hyphen (core Nextflow option)

### `-c`
Specify the path to a specific config file (this is a core NextFlow command).

**NB:** Single hyphen (core Nextflow option)

Note - you can use this to override pipeline defaults.

### `--maxMemory`
Use to set a top-limit for the default memory requirement for each process.
Should be a string in the format integer-unit. eg. `--maxMemory '8.GB'`

### `--maxTime`
Use to set a top-limit for the default time requirement for each process.
Should be a string in the format integer-unit. eg. `--maxTime '2.h'`

### `--maxCpus`
Use to set a top-limit for the default CPU requirement for each process.
Should be a string in the format integer-unit. eg. `--maxCpus 1`

### `--multiqcConfig`
Specify a path to a custom MultiQC configuration file.


## Profile parameters

### `--condaCacheDir`

Whenever you use the `conda` or `multiconda` profiles, the conda environments are created in the ``${HOME}/conda-cache-nextflow`` folder by default. This folder can be changed using the `--condaCacheDir` option.


### `--globalPath`

When you use `path` or `multipath` profiles, the ``path`` and ``multipath`` folders where are installed the tools can be changed at runtime with the ``--globalPath`` option.


### `--queue`

If you want your job to be submitted on a specific ``queue`` when you use the `cluster` profile, use the option ``--queue`` with the name of the queue in the command line.


### `--singularityImagePath`

When you use the `singularity` profile, the path to the singularity containers can be changed at runtime with the ``--singularityImagePath`` option.


