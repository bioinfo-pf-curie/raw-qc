
# Outputs

<!-- TODO update with the output of your pipeline -->

This document describes the output produced by the pipeline. Most of the plots are taken from the MultiQC report, which summarises results at the end of the pipeline.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes the data using the steps presented in the main README file.

Briefly, the workflow runs adapter trimming on fastq files. The user can choose [Trim Galore](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/), [Fastp](https://github.com/OpenGene/fastp) or [Atropos](https://github.com/jdidion/atropos) in order to detect and remove adapters. Further,  It peforms quality controls and multi-genome mapping on raw sequencing reads. 

The directories listed below will be created in the output directory after the pipeline has finished.

## Sequence trimming

### Trim Galore

[Trim Galore](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/) is a wrapper tool around [Cutadapt](https://github.com/marcelm/cutadapt/) to peform quality and adapter trimming on FastQ files. By default, Trim Galore will automatically detect and trim the appropriate adapter sequence. By default, `raw-qc` is using `TrimGalore`

**Output directory: `trimming`**

* `sample_trimmed_R[1,2].gz`
  * trimmed Reads [1,2] . 
* `sample.json`
  * report JSON format result for further interpreting..
* `sample.log`
  * statistical reports.

### Fastp
[Fastp] (https://github.com/OpenGene/fastp) is another tool designed to provide fast all-in-one preprocessing for FastQ files. This tool is developed in C++ with multithreading supported to afford high performance.

**Output directory: `trimming`**

* `sample_trimmed_R[1,2].gz`
  * trimmed Reads [1,2] . 
* `sample.json`
  * report JSON format result for further interpreting..
* `sample.log`
  * statistical reports.


### Atropos

[Atropos](https://github.com/jdidion/atropos) is tool for specific, sensitive, and speedy trimming of NGS reads.

**Output directory: `trimming`**

* `sample_trimmed_R[1,2].gz`
  * trimmed Reads [1,2] . 
* `sample.json`
  * report JSON format result for further interpreting..
* `sample.log`
  * statistical reports.

The `General Metrics` are presented in the MultiQC report as a statistical information on sequences before and after trimming.


## Sequencing quality

### FastQC
[FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) gives general quality metrics about your reads. It provides information about the quality score distribution across your reads, the per base sequence content (%T/A/G/C). You get information about adapter contamination and other overrepresented sequences.

For further reading and documentation see the [FastQC help](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/).

**Output directory: `fastqc`**

* `sample_fastqc.html`
  * FastQC report, containing quality metrics for your untrimmed raw fastq files.
* `zips/sample_fastqc.zip`
  * zip file containing the FastQC report, tab-delimited data file and plot images.

### FastQ Screen
[FastQ Screen](https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/) maps sample reads on a list of reference genomes for assessing sample contamination and the ratio of the excepted genome in the sample. It creates a report file with values for each genome.

**Output directory: `fastqScreen`**

* `sample_trimmed_R[1,2]_screen.html`
  * FastqScreen report, containing multi-genome mapping for your trimmed raw fastq files in html format.
* `sample_trimmed_R[1,2]_screen.txt`
  * FastqScreen report, containing multi-genome mapping for your trimmed raw fastq files in txt format.
* `fastq_screen_databases.config`
  * a list of reference genomes for assessing sample contamination.
* `sample_trimmed_R[1,2].tagged_filter.fastq.gz`
  * a library of sequences in Fastq format against a set of sequence databases.


## MultiQC
[MultiQC](http://multiqc.info) is a visualisation tool that generates a single HTML report summarising all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available within the report data directory.

The pipeline has special steps which allow the software versions used to be reported in the MultiQC output for future traceability.

**Output directory: `multiqc`**

* `multiqc_report.html`
  * MultiQC report - a standalone HTML file that can be viewed in your web browser.
* `multiqc_data/`
  * Directory containing parsed statistics from the different tools used in the pipeline.
