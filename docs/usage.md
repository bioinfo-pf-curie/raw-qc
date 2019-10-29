# curie/rawqc: Usage

## Table of contents

* [General Nextflow info](#general-nextflow-info)
* [Running the pipeline](#running-the-pipeline)
* [Main arguments](#main-arguments)
    * [`profile`](#profile)
    * [`reads`](#reads)
    * [`singleEnd`](#singleend)
* [Trimming tool](#trimming-tool)
* [Trimming options](#trimming-options)
    * [`adapter`](#adapter)
    * [`qualtrim`](#qualtrim)
    * [`ntrim`](#ntrim)
    * [`two_colour`](#two_colour)
    * [`minlen`](#minlen)
* [Library Prep Presets](#library-prep-presets)
    * [`pico_v1`](#pico_v1)
    * [`pico_v2`](#pico_v2)
    * [`polyA`](#polya)
* [Other command line parameters](#other-command-line-parameters)
    * [`skip_fastqc_raw`](#other-command-line-parameters)
    * [`skip_trimming` ](#other-command-line-parameters)
    * [`skip_fastqc_trim`](#other-command-line-parameters)
    * [`skip_multiqc`](#other-command-line-parameters)
    * [`outdir`](#outdir)
    * [`name`](#name)
    * [`resume`](#resume)
    * [`c`](#c)
    * [`max_memory`](#max_memory)
    * [`max_time`](#max_time)
    * [`max_cpus`](#max_cpus)

## General Nextflow info
Nextflow handles job submissions on SLURM or other environments, and supervises running the jobs. Thus the Nextflow process must run until the pipeline is finished. We recommend that you put the process running in the background through `screen` / `tmux` or similar tool. Alternatively you can run nextflow within a cluster job submitted your job scheduler.

It is recommended to limit the Nextflow Java virtual machines memory. We recommend adding the following line to your environment (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
## Running the pipeline
The typical command for running the pipeline is as follows:
```bash
nextflow run main.nf --reads '*_R{1,2}.fastq.gz' -profile conda
```

This will launch the pipeline with the `conda` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work            # Directory containing the nextflow working files
results         # Finished results (configurable, see below)
.nextflow_log   # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

## Main arguments

### `-profile`
Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments. Note that multiple profiles can be loaded, for example: `-profile singularity` - the order of arguments is important!

If `-profile` is not specified at all the pipeline will be run locally and expects all software to be installed and available on the `PATH`.

* `conda`
    * A generic configuration profile to be used with [conda](https://conda.io/docs/)
	* Pulls most software from [Bioconda](https://bioconda.github.io/)
* `condaPath`
    * A generic configuration profile to be used with [conda](https://conda.io/docs/)
    * Use the conda images available on the cluster
* `singularity`
    * A generic configuration profile to be used with [Singularity](http://singularity.lbl.gov/)
    * Use the singularity images available on the cluster
* `cluster`
    * Run the workflow on the computational cluster
* `test`
    * A profile with a complete configuration for automated testing
    * Includes links to test data so needs no other parameters
	* Use the singularity images set up* Use the conda images available on


### `--reads`
Use this to specify the location of your input FastQ files. For example:

```bash
--reads 'path/to/data/sample_*_{1,2}.fastq'
```

Please note the following requirements:

1. The path must be enclosed in quotes
2. The path must have at least one `*` wildcard character
3. When using the pipeline with paired end data, the path must use `{1,2}` notation to specify read pairs.

If left unspecified, a default pattern is used: `data/*{1,2}.fastq.gz`

### `--singleEnd`
By default, the pipeline expects paired-end data. If you have single-end data, you need to specify `--singleEnd` on the command line when you launch the pipeline. A normal glob pattern, enclosed in quotation marks, can then be used for `--reads`. For example:

```bash
--singleEnd --reads '*.fastq'
```

It is not possible to run a mixture of single-end and paired-end files in one run.

## Trimming tool

By default, the pipeline uses `TrimGalore!` to automate quality and adapter trimming as well as quality control.
If you prefer, you can use `fastp` or `atropos` as the trimming tool instead. 

The benchmarking for these three tools is in the table below.

|                      | TrimGalore |  Fastp   | Atropos  |
|----------------------|------------|----------|----------|
| pico protocol        |  &#x2611;  | &#x2611; |          |
| 3'seq protocol       |  &#x2611;  |          | &#x2611; |
| 2-colour support     |  &#x2611;  | &#x2611; | &#x2611; |
| Min adapter overlap  |  &#x2611;  |          | &#x2611; |
| Adapter detection    |  +++       | ++       | -        |
| Poly N trimming      |  &#x2611;  |          | &#x2611; |
| Speed                |  ++        | +++      | +        |

Note that the current version does not implement the adapter detection using `Atropos` as we detected some unexpected results during our internal tests.

## Trimming options:

### `--adapter`

Adapter sequence to be trimmed.

   - [`auto`]: By default, the pipeline tries to auto-detect the adapter.
   - [`truseq`, `nextera`, `smallrna`]: Otherwise, you can specified the name of the adapter to remove at the 3' end of the reads (Illumina universal, Nextera transposase or Illumina)

### `--qualtrim`

Trim low-quality bases at the end of the reads in addition to adapter removal.
Quality trimming will be performed first, and adapter trimming is carried in a second round. 
Other files are quality and adapter trimmed in a single pass.
Default Phred score: 20.

### `--ntrim`

Removes 'N's from either side of the read. If one read's number of N base is >ntrim, then this read/pair is discarded. Default is 5 (int [=5]).

### `--two_colour`  

Set special options for two colours sequencers (NextSeq- and NovaSeq-platforms), where basecalls without any signal are called as high-quality G bases.

### `--minlen`

Discard reads that became shorter than length INT because of either quality or adapter trimming. Default: 10 bp.

##  `Library Prep Presets`

###  `--pico_v1`

Sets version 1 for the SMARTer Stranded Total RNA-Seq Kit - Pico Input kit. Only for trimgalore and fastp.

### `--pico_v2` 

Sets version 2 for the SMARTer Stranded Total RNA-Seq Kit - Pico Input kit. Only for trimgalore and fastp.

### `--polyA`

Specific option for polyA-sequencing.
After adapter trimming, the pipeline tries to detect and remove polyA tail at the 3' end of the reads that will failed to align on the reference genome (A{10}).

## Other command line parameters

The pipeline contains diffrent steps. Sometimes, it may not be desirable to run all of them if time and compute resources are limited.
The following options make this easy:

* `--skip_fastqc_raw` -  Skip FastQC on raw sequencing reads
* `--skip_trimming` -    Skip trimming step
* `--skip_fastqc_trim` - Skip FastQC on trimmed sequencing reads
* `--skip_multiqc` -     Skip MultiQC step

## Job resources

### Automatic resubmission

Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with an error code of `143` (exceeded requested resources) it will automatically resubmit with higher requests (2 x original, then 3 x original). If it still fails after three times then the pipeline is stopped.

### Custom resource requests

Wherever process-specific requirements are set in the pipeline, the default value can be changed by creating a custom config file. See the files hosted at [`rawqc/configs`](https://github.com/git/raw-qc/conf) for examples.

Please make sure to also set the `-w/--work-dir` and `--outdir` parameters to a S3 storage bucket of your choice - you'll get an error message notifying you if you didn't.

### `--outdir`

The output directory where the results will be saved.

### `--name`

Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.

This is used in the MultiQC report (if not default).

**NB:** Single hyphen (core Nextflow option)

### `-resume`

Specify this when restarting a pipeline. Nextflow will used cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously.

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

**NB:** Single hyphen (core Nextflow option)

### `-c`

Specify the path to a specific config file (this is a core NextFlow command).

Note - you can use this to override pipeline defaults.

### `--max_memory`

Use to set a top-limit for the default memory requirement for each process.
Should be a string in the format integer-unit. eg. `--max_memory '8.GB'`

### `--max_time`

Use to set a top-limit for the default time requirement for each process.
Should be a string in the format integer-unit. eg. `--max_time '2.h'`

### `--max_cpus`

Use to set a top-limit for the default CPU requirement for each process.
Should be a string in the format integer-unit. eg. `--max_cpus 1`



