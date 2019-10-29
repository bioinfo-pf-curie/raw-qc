# rawqc: Output

This document describes the output produced by the pipeline. All the plots are taken from the MultiQC report, which summarises results at the end of the pipeline.

## Pipeline overview
The pipeline is built using [Nextflow](https://www.nextflow.io/)
and processes data using the following steps:

* [Trimming](#trimming) -  adapter trimming
* [FastQC](#fastqc) - read quality control
* [MultiQC](#multiqc) - aggregate report, describing results of the whole pipeline



## Trimming

The goal of curie/rawqc pipeline is removal of adapter contamination and trimming of low quality regions. In this way, we applied three following trimming tools which use Cutadapt for adapter trimming.

**Output directory for trim_galore: `results/trimming`**

  * outputs for [Trim_galore](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/)
    
     * NB: Only if `--trimtool` has been set as `Trim_galore`.
        
     * `sample_R1_trimmed.fastq.gz`, `sample_R2_trimmed.fastq.gz`
        * Trimmed FastQ data, reads 1 and 2.
     *  `sample_R1.fastq.gz_trimming_report.txt`, `sample_R2.fastq.gz_trimming_report.txt`
        * Trimming report
        
  * outpts for [Fastp](https://github.com/OpenGene/fastp)
  
     * NB: Only if `--trimtool` has been set as `fastp`.
        
     * `sample_R1_trimmed.fastq.gz`, `sample_R2_trimmed.fastq.gz`
        * Trimmed FastQ data, reads 1 and 2.
     *  `sample.fastp.json`
        * Trimming report
     *  `logs/sample_fasp.log`
        * Trimming report (describes which parameters that were used)
        
  
 * outputs for [Atropos](https://github.com/jdidion/atropos)

     * NB: Only if `--trimtool` has been set as `atropos`.
        
     * `sample_R1_trimmed.fq.gz`, `sample_R2_trimmed.fq.gz`
        * Trimmed FastQ data, reads 1 and 2.
     *  `sample_R1_trimming_report.json`, `sample_R1_trimming_report.yaml`, `sample_R1_trimming_report.xml`
        * Trimming report

> **NB:** Single-end data will have slightly different file names.

## FastQC
[FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) gives general quality metrics about your reads. It provides information about the quality score distribution across your reads, the per base sequence content (%T/A/G/C). You get information about adapter contamination and other overrepresented sequences.

For further reading and documentation see the [FastQC help](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/).

> **NB:** The FastQC plots displayed in the MultiQC report shows `trimmed` and/or `untrimmed` reads. Only if `skip_fastqc_raw` and `skip_fastqc_trim` have not been specified. They may contain adapter sequence and potentially regions with low quality.

**Output directory for untrimmed reads: `results/fastqc`**

* `sample_fastqc.html`
     * FastQC report, containing quality metrics for your untrimmed raw fastq files
* `zips/sample_fastqc.zip`
     * zip file containing the FastQC report, tab-delimited data file and plot images

**Output directory for trimmed reads:`results/fastqc_trimmed`**

* `sample_trimmed_fastqc.html`
     * FastQC report, containing quality metrics for your untrimmed raw fastq files
* `zips/sample_trimmed_fastqc.zip`
     * zip file containing the FastQC report, tab-delimited data file and plot images

## MultiQC
[MultiQC](http://multiqc.info) is a visualisation tool that generates a single HTML report summarising all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available in within the report data directory.

The pipeline has special steps which allow the software versions used to be reported in the MultiQC output for future traceability.

**Output directory: `results/multiqc`**

* `Project_multiqc_report.html`
    * MultiQC report - a standalone HTML file that can be viewed in your web browser
* `Project_multiqc_data/`
    * Directory containing parsed statistics from the different tools used in the pipeline

> **NB:** The MultiQC plots displayed Only if `skip_multiqc` has not been specified. 

For more information about how to use MultiQC reports, see http://multiqc.info
