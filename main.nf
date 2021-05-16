#!/usr/bin/env nextflow

/*
Copyright Institut Curie 2019
This software is a computer program whose purpose is to analyze high-throughput sequencing data.
You can use, modify and/ or redistribute the software under the terms of license (see the LICENSE file for more details).
The software is distributed in the hope that it will be useful, but "AS IS" WITHOUT ANY WARRANTY OF ANY KIND. 
Users are therefore encouraged to test the software's suitability as regards their requirements in conditions enabling the security of their systems and/or data. 
The fact that you are presently reading this means that you have had knowledge of the license and that you accept its terms.
*/


/*
========================================================================================
i                         Raw-QC
========================================================================================
 Raw QC Pipeline.
 #### Homepage / Documentation
 https://gitlab.curie.fr/data-analysis/raw-qc
----------------------------------------------------------------------------------------
*/


def helpMessage() {
    if ("${workflow.manifest.version}" =~ /dev/ ){
       dev_mess = file("$baseDir/assets/dev_message.txt")
       log.info dev_mess.text
    }

    log.info"""
    raw-qc v${workflow.manifest.version}
    ==========================================================

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
      --rna_lig                     Sets trimming setting for the stranded mRNA prep Ligation-Illumina. Only for trimgalore and fastp.
      --polyA                       Sets trimming setting for 3'-seq analysis with polyA tail detection

    Other options:
      --outdir 'PATH'               The output directory where the results will be saved
      -name 'NAME'                  Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic
      --metadata 'FILE'             Add metadata file for multiQC report

    Skip options:
      --skip_fastqc_raw             Skip FastQC on raw sequencing reads
      --skip_trimming               Skip trimming step
      --skip_fastqc_trim            Skip FastQC on trimmed sequencing reads
      --skip_fastq_sreeen           Skip FastQScreen on trimmed sequencing reads
      --skip_multiqc                Skip MultiQC step

    =======================================================
    Available Profiles

      -profile test                Set up the test dataset
      -profile conda               Build a new conda environment before running the pipeline
      -profile condaPath           Use a pre-build conda environment already installed on our cluster
      -profile singularity         Use the Singularity images for each process
      -profile cluster             Run the workflow on the cluster, instead of locally

    """.stripIndent()
}


// Show help emssage
if (params.help){
    helpMessage()
    exit 0
}


// Has the run name been specified by the user?
//  this has the bonus effect of catching both -name and --name
custom_runName = params.name
if( !(workflow.runName ==~ /[a-z]+_[a-z]+/) ){
  custom_runName = workflow.runName
}


// Validate inputs 
if (params.trimtool != 'trimgalore' && params.trimtool != 'atropos' && params.trimtool != 'fastp' ){
    exit 1, "Invalid trimming tool option: ${params.trimtool}. Valid options: 'trimgalore', 'atropos', 'fastp'"
} 

if (params.adapter != 'truseq' && params.adapter != 'nextera' && params.adapter != 'smallrna' && params.adapter!= 'auto' ){
    exit 1, "Invalid adaptator seq tool option: ${params.adapter}. Valid options: 'truseq', 'nextera', 'smallrna', 'auto'"
}

if (params.adapter == 'auto' && params.trimtool == 'atropos') {
   exit 1, "Cannot use Atropos without specifying --adapter sequence."
}

if (params.adapter == 'smallrna' && !params.singleEnd){
    exit 1, "smallRNA requires singleEnd data."
}

/*
if (params.ntrim && params.trimtool == 'fastp') {
  log.warn "[raw-qc] The 'ntrim' option is not availabe for the 'fastp' trimmer. Option is ignored."
}
*/

if (params.pico_v1 && params.pico_v2 && params.rna_lig){
    exit 1, "Invalid SMARTer kit option at the same time for pico_v1 && pico_v2 && rna_lig"
}

if (params.pico_v1 && params.pico_v2 && params.trimtool == 'atropos'){
    exit 1, "Cannot use Atropos for pico preset"
}

if (params.singleEnd && params.pico_v2){
   exit 1, "Cannot use --pico_v2 for single end."
}



// Stage config files
ch_multiqc_config = Channel.fromPath(params.multiqc_config)
ch_output_docs = Channel.fromPath("$baseDir/docs/output.md")
ch_adaptor_file_detect = Channel.fromPath("$baseDir/assets/sequencing_adapters.fa")
ch_adaptor_file_defult = Channel.fromPath("$baseDir/assets/sequencing_adapters.fa")

// FastqScreen

Channel
    .from(params.genomes.fastqScreenGenomes)
    .set{ fastqScreenGenomeCh }

//Channel
//    .fromList(params.genomes.fastqScreenGenomes.values().collect{file(it)})
//    .set{ fastqScreenGenomeCh }

/*
 * CHANNELS
 */
if ((params.reads && params.samplePlan) || (params.readPaths && params.samplePlan)){
   exit 1, "Input reads must be defined using either '--reads' or '--samplePlan' parameter. Please choose one way"
}

if(params.samplePlan){
   if(params.singleEnd){
      Channel
         .from(file("${params.samplePlan}"))
         .splitCsv(header: false)
         .map{ row -> [ row[1], [file(row[2])]] }
         .into { read_files_fastqc; read_files_trimgalore; read_files_atropos_detect; read_files_atropos_trim; read_files_fastp; read_files_trimreport; read_files_rawdatareport; read_fastqscreen}
   }else{
      Channel
         .from(file("${params.samplePlan}"))
         .splitCsv(header: false)
         .map{ row -> [ row[1], [file(row[2]), file(row[3])]] }
         .into { read_files_fastqc; read_files_trimgalore; read_files_atropos_detect; read_files_atropos_trim; read_files_fastp; read_files_trimreport; read_files_rawdatareport; read_fastqscreen }
   }
   params.reads=false
}
else if(params.readPaths){
    if(params.singleEnd){
        Channel
            .from(params.readPaths)
            .map { row -> [ row[0], [file(row[1][0])]] }
            .ifEmpty { exit 1, "params.readPaths was empty - no input files supplied" }
            .into { read_files_fastqc; read_files_trimgalore; read_files_atropos_detect; read_files_atropos_trim; read_files_fastp; read_files_trimreport; read_files_rawdatareport; read_fastqscreen}
    } else {
        Channel
            .from(params.readPaths)
            .map { row -> [ row[0], [file(row[1][0]), file(row[1][1])]] }
            .ifEmpty { exit 1, "params.readPaths was empty - no input files supplied" }
            .into { read_files_fastqc; read_files_trimgalore; read_files_atropos_detect; read_files_atropos_trim; read_files_fastp; read_files_trimreport; read_files_rawdatareport; read_fastqscreen }
    }
} else {
    Channel
        .fromFilePairs( params.reads, size: params.singleEnd ? 1 : 2 )
        .ifEmpty { exit 1, "Cannot find any reads matching: ${params.reads}\nNB: Path needs to be enclosed in quotes!\nNB: Path requires at least one * wildcard!\nIf this is single-end data, please specify --singleEnd on the command line\
." }
        .into { read_files_fastqc; read_files_trimgalore; read_files_atropos_detect; read_files_atropos_trim; read_files_fastp; read_files_trimreport; read_files_rawdatareport }
}

/*
 * Make sample plan if not available
 */

if (params.samplePlan){
  ch_splan = Channel.fromPath(params.samplePlan)
}else if(params.readPaths){
  if (params.singleEnd){
    Channel
       .from(params.readPaths)
       .collectFile() {
         item -> ["sample_plan.csv", item[0] + ',' + item[0] + ',' + item[1][0] + '\n']
        }
       .set{ ch_splan }
  }else{
     Channel
       .from(params.readPaths)
       .collectFile() {
         item -> ["sample_plan.csv", item[0] + ',' + item[0] + ',' + item[1][0] + ',' + item[1][1] + '\n']
        }
       .set{ ch_splan }
  }
}else{
  if (params.singleEnd){
    Channel
       .fromFilePairs( params.reads, size: 1 )
       .collectFile() {
          item -> ["sample_plan.csv", item[0] + ',' + item[0] + ',' + item[1][0] + '\n']
       }
       .set { ch_splan }
  }else{
    Channel
       .fromFilePairs( params.reads, size: 2 )
       .collectFile() {
          item -> ["sample_plan.csv", item[0] + ',' + item[0] + ',' + item[1][0] + ',' + item[1][1] + '\n']
       }
       .set { ch_splan }
   }
}

if ( params.metadata ){
   Channel
       .fromPath( params.metadata )
       .ifEmpty { exit 1, "Metadata file not found: ${params.metadata}" }
       .set { ch_metadata }
}


// Header log info
if ("${workflow.manifest.version}" =~ /dev/ ){
   dev_mess = file("$baseDir/assets/dev_message.txt")
   log.info dev_mess.text
}

log.info """=======================================================

raw-qc v${workflow.manifest.version}"
======================================================="""
def summary = [:]
summary['Pipeline Name']  = 'rawqc'
summary['Pipeline Version'] = workflow.manifest.version
summary['Run Name']     = custom_runName ?: workflow.runName
summary['Metadata']     = params.metadata
if (params.samplePlan) {
   summary['SamplePlan']   = params.samplePlan
}else{
   summary['Reads']        = params.reads
}
summary['Data Type']    = params.singleEnd ? 'Single-End' : 'Paired-End'
summary['Trimming tool']= params.trimtool
summary['Adapter']= params.adapter
summary['Min quality']= params.qualtrim
summary['Min len']= params.minlen
summary['N trim']= params.ntrim ? 'True' : 'False'
summary['Two colour']= params.two_colour ? 'True' : 'False'
if (params.pico_v1) {
   summary['Pico_v1'] = 'True'
}
if(params.pico_v2) {
   summary['Pico_v2'] = 'True'
}
if (!params.pico_v1 && !params.pico_v2) {
   summary['Pico'] = 'False'
}
summary['RNA_Lig']=params.rna_lig ? 'True' : 'False'
summary['PolyA']= params.polyA ? 'True' : 'False'
summary['Max Memory']   = params.maxMemory
summary['Max CPUs']     = params.maxCpus
summary['Max Time']     = params.maxTime
summary['Container Engine'] = workflow.containerEngine
summary['Current home']   = "$HOME"
summary['Current user']   = "$USER"
summary['Current path']   = "$PWD"
summary['Working dir']    = workflow.workDir
summary['Output dir']     = params.outdir
summary['Config Profile'] = workflow.profile

if(params.email) summary['E-mail Address'] = params.email
log.info summary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "========================================="

/* Creates a file at the end of workflow execution */
workflow.onComplete {
  File woc = new File("${params.outdir}/raw-qc.workflow.oncomplete.txt")
  Map endSummary = [:]
  endSummary['Completed on'] = workflow.complete
  endSummary['Duration']     = workflow.duration
  endSummary['Success']      = workflow.success
  endSummary['exit status']  = workflow.exitStatus
  endSummary['Error report'] = workflow.errorReport ?: '-'
  String endWfSummary = endSummary.collect { k,v -> "${k.padRight(30, '.')}: $v" }.join("\n")
  println endWfSummary
  String execInfo = "Summary\n${endWfSummary}\n"
  woc.write(execInfo)
}

/*
================================================================================
                                   First QC on raw data [FastQC]
================================================================================
*/


process fastqc {
   label 'fastqc'
   label 'lowCpu'
   label 'minMem'
   publishDir "${params.outdir}/fastqc", mode: 'copy'

   when:
   !params.skip_fastqc_raw

   input:
   set val(name), file(reads) from read_files_fastqc

   output:
   file( "*_fastqc.{zip,html}") into fastqc_results
   file("v_fastqc.txt") into fastqc_version

   script:
   """
   fastqc -q $reads -t ${task.cpus}
   fastqc --version &> v_fastqc.txt 2>&1 || true
   """
}

/*
================================================================================
                                   Reads Trimming
================================================================================
*/


process trimGalore {
  label 'trimgalore'
  label 'lowCpu'
  label 'minMem'
  publishDir "${params.outdir}/trimming", mode: 'copy'

  when:
  params.trimtool == "trimgalore" && !params.skip_trimming

  input:
  set val(name), file(reads) from read_files_trimgalore

  output:
  set val(name), file("*fastq.gz") into trim_reads_trimgalore, trimgalore_reads
  set val(name), file("*trimming_report.txt") into trim_results_trimgalore, report_results_trimgalore
  file("v_trimgalore.txt") into trimgalore_version

  script:
  prefix = reads[0].toString() - ~/(_1)?(_2)?(_R1)?(_R2)?(.R1)?(.R2)?(_val_1)?(_val_2)?(\.fq)?(\.fastq)?(\.gz)?$/
  ntrim = params.ntrim ? "--trim-n" : ""
  qual_trim = params.two_colour ?  "--2colour ${params.qualtrim}" : "--quality ${params.qualtrim}"
  adapter = ""
  pico_opts = ""
  lig_opts = ""
  if (params.singleEnd) {
    if (params.pico_v1) {
       pico_opts = "--clip_r1 3 --three_prime_clip_r2 3"
    }
    if (params.adapter == 'truseq'){
      adapter = "--adapter ${params.truseq_r1}"
    }else if (params.adapter == 'nextera'){
      adapter = "--adapter ${params.nextera_r1}"
    }else if (params.adapter == 'smallrna'){
      adapter = "--adapter ${params.smallrna_r1}"
    }

    if (!params.polyA){
    """
    trim_galore --version &> v_trimgalore.txt 2>&1 || true
    trim_galore ${adapter} ${ntrim} ${qual_trim} \
                --length ${params.minlen} ${pico_opts} \
                --gzip $reads --basename ${prefix} --cores ${task.cpus}
    mv ${prefix}_trimmed.fq.gz ${prefix}_trimmed_R1.fastq.gz
    """
    }else{
    """
    trim_galore --version &> v_trimgalore.txt 2>&1 || true
    trim_galore ${adapter} ${ntrim} ${qual_trim} \
    		--length ${params.minlen} ${pico_opts} \
                --gzip $reads --basename ${prefix} --cores ${task.cpus}
    trim_galore -a "A{10}" ${qual_trim} --length ${params.minlen} \
                --gzip ${prefix}_trimmed.fq.gz --basename ${prefix}_polyA --cores ${task.cpus}
    rm ${prefix}_trimmed.fq.gz
    mv ${prefix}_polyA_trimmed_trimmed.fq.gz ${prefix}_trimmed_R1.fastq.gz
    mv ${prefix}_trimmed.fq.gz_trimming_report.txt ${prefix}_polyA_trimmingreport.txt
    """
    }
  }else {
    if (params.pico_v1) {
       pico_opts = "--clip_r1 3 --three_prime_clip_r2 3"
    }
    if (params.pico_v2) {
       pico_opts = "--clip_r2 3 --three_prime_clip_r1 3"
    }
    if (params.rna_lig) {
       lig_opts = "--clip_r1 1 --three_prime_clip_r2 2 --clip_r2 1 --three_prime_clip_r1 2"
    }

    if (params.adapter == 'truseq'){
      adapter ="--adapter ${params.truseq_r1} --adapter2 ${params.truseq_r2}"
    }else if (params.adapter == 'nextera'){
      adapter ="--adapter ${params.nextera_r1} --adapter2 ${params.nextera_r2}"
    }
    
    if (!params.polyA){
    """
    trim_galore --version &> v_trimgalore.txt 2>&1 || true
    trim_galore ${adapter} ${ntrim} ${qual_trim} \
                --length ${params.minlen} ${pico_opts} ${lig_opts} \
                --paired --gzip $reads --basename ${prefix} --cores ${task.cpus}
    mv ${prefix}_R1_val_1.fq.gz ${prefix}_trimmed_R1.fastq.gz
    mv ${prefix}_R2_val_2.fq.gz ${prefix}_trimmed_R2.fastq.gz
    """
    }else{
    """
    trim_galore --version &> v_trimgalore.txt 2>&1 || true
    trim_galore ${adapter} ${ntrim} ${qual_trim} \
                --length ${params.minlen} ${pico_opts} ${lig_opts} \
                --paired --gzip $reads --basename ${prefix} --cores ${task.cpus}

    trim_galore -a "A{10}" ${qual_trim} --length ${params.minlen} \
                 --paired --gzip ${prefix}_R1_val_1.fq.gz ${prefix}_R2_val_2.fq.gz --basename ${prefix}_polyA --cores ${task.cpus}

    mv ${prefix}_polyA_R1_val_1.fq.gz ${prefix}_trimmed_R1.fastq.gz
    mv ${prefix}_polyA_R2_val_2.fq.gz ${prefix}_trimmed_R2.fastq.gz
    mv ${prefix}_R1_val_1.fq.gz_trimming_report.txt ${prefix}_R1_polyA_trimmingreport.txt
    mv ${prefix}_R2_val_2.fq.gz_trimming_report.txt ${prefix}_R2_polyA_trimmingreport.txt
    rm ${prefix}_R1_val_1.fq.gz ${prefix}_R2_val_2.fq.gz
    """
    }
  }
   
}

//--clip_r1 1 --three_prime_clip_r2 2 --clip_r2 1 --three_prime_clip_r1 2

process atroposTrim {
  label 'atropos'
  label 'lowCpu'
  label 'minMem'
  publishDir "${params.outdir}/trimming", mode: 'copy'

  
  when:
  params.trimtool == "atropos" && !params.skip_trimming && params.adapter != ""
  
  input:
  set val(name), file(reads) from read_files_atropos_trim
  file sequences from ch_adaptor_file_defult.collect()

  output:

  file("*trimming_report*") into trim_results_atropos
  set val(name), file("*trimmed*fastq.gz") into trim_reads_atropos, atropos_reads
  set val(name), file("*.json") into report_results_atropos
  file("v_atropos.txt") into atropos_version

  script:
  prefix = reads[0].toString() - ~/(_1)?(_2)?(_R1)?(_R2)?(.R1)?(.R2)?(_val_1)?(_val_2)?(\.fq)?(\.fastq)?(\.gz)?$/
  ntrim = params.ntrim ? "--trim-n" : ""
  nextseq_trim = params.two_colour ? "--nextseq-trim" : ""
  polyA_opts = params.polyA ? "-a A{10}" : ""

  if (params.singleEnd) {
  """
  if  [ "${params.adapter}" == "truseq" ]; then
     echo -e ">truseq_adapter_r1\n${params.truseq_r1}" > ${prefix}_detect.0.fasta
  elif [ "${params.adapter}" == "nextera" ]; then
     echo -e ">nextera_adapter_r1\n${params.nextera_r1}" > ${prefix}_detect.0.fasta
  elif [ "${params.adapter}" == "smallrna" ]; then
     echo -e ">smallrna_adapter_r1\n${params.smallrna_r1}" > ${prefix}_detect.0.fasta
  fi
  atropos &> v_atropos.txt 2>&1 || true
  atropos trim -se ${reads} \
         --adapter file:${prefix}_detect.0.fasta \
         --times 3 --overlap 1 \
         --minimum-length ${params.minlen} --quality-cutoff ${params.qualtrim} \
         ${ntrim} ${nextseq_trim} ${polyA_opts} \
         --threads ${task.cpus} \
         -o ${prefix}_trimmed_R1.fastq.gz \
         --report-file ${prefix}_trimming_report \
         --report-formats txt json
  """
  } else {
  """
  if [ "${params.adapter}" == "truseq" ]; then
     echo -e ">truseq_adapter_r1\n${params.truseq_r1}" > ${prefix}_detect.0.fasta
     echo -e ">truseq_adapter_r2\n${params.truseq_r2}" > ${prefix}_detect.1.fasta
  elif [ "${params.adapter}" == "nextera" ]; then
     echo -e ">nextera_adapter_r1\n${params.nextera_r1}" > ${prefix}_detect.0.fasta
     echo -e ">nextera_adapter_r2\n${params.nextera_r2}" > ${prefix}_detect.1.fasta
  fi
  atropos &> v_atropos.txt 2>&1 || true
  atropos -pe1 ${reads[0]} -pe2 ${reads[1]} \
         --adapter file:${prefix}_detect.0.fasta -A file:${prefix}_detect.1.fasta \
         -o ${prefix}_trimmed_R1.fastq.gz -p ${prefix}_trimmed_R2.fastq.gz  \
         --times 3 --overlap 1 \
         --minimum-length ${params.minlen} --quality-cutoff ${params.qualtrim} \
         ${ntrim} ${nextseq_trim} ${polyA_opts} \
         --threads ${task.cpus} \
         --report-file ${prefix}_trimming_report \
         --report-formats txt json
  """
  }
}

process fastp {
  label 'fastp'
  label 'lowCpu'
  label 'minMem'
  publishDir "${params.outdir}/trimming", mode: 'copy'


  when:
  params.trimtool == "fastp" && !params.skip_trimming
  
  input:
  set val(name), file(reads) from read_files_fastp
  
  output:

  set val(name), file("*trimmed*fastq.gz") into trim_reads_fastp, fastp_reads
  set val(name), file("*.{json,log}") into trim_results_fastp, report_results_fastp
  file("v_fastp.txt") into fastp_version

  script:
  prefix = reads[0].toString() - ~/(_1)?(_2)?(_R1)?(_R2)?(.R1)?(.R2)?(_val_1)?(_val_2)?(\.fq)?(\.fastq)?(\.gz)?$/
  nextseq_trim = params.two_colour ? "--trim_poly_g" : "--disable_trim_poly_g"
  ntrim = params.ntrim ? "" : "--n_base_limit 0"
  pico_opts = ""
  polyA_opts = params.polyA ? "--trim_poly_x" : ""
  adapter = ""

  if (params.singleEnd) {
    // we don't usually have pico_version2 for single-end.
    if (params.pico_v1) {
       pico_opts = "--trim_front1 3 --trim_tail1 3"
    } 

    if (params.adapter == 'truseq'){
      adapter ="--adapter_sequence ${params.truseq_r1}"
    }else if (params.adapter == 'nextera'){
      adapter ="--adapter_sequence ${params.nextera_r1}"
    }else if (params.adapter == 'smallrna'){
      adapter ="--adapter_sequence ${params.smallrna_r1}"
    }
    """
    fastp --version &> v_fastp.txt 2>&1 || true
    fastp ${adapter} \
    --qualified_quality_phred ${params.qualtrim} \
    ${nextseq_trim} ${pico_opts} ${polyA_opts} \
    ${ntrim} \
    --length_required ${params.minlen} \
    -i ${reads} -o ${prefix}_trimmed_R1.fastq.gz \
    -j ${prefix}.fastp.json -h ${prefix}.fastp.html\
    --thread ${task.cpus} 2> ${prefix}_fasp.log
    """
  } else {
    if (params.pico_v1) {
       pico_opts = "--trim_front1 3 --trim_tail2 3"
    }
    if (params.pico_v2) {
       pico_opts = "--trim_front2 3 --trim_tail1 3"
    }

    if (params.rna_lig) {
       lig_opts = "--trim_front1 1 --trim_tail2 2 --trim_front2 1 --trim_tail1 2"
    }

    if (params.adapter == 'truseq'){
      adapter ="--adapter_sequence ${params.truseq_r1} --adapter_sequence_r2 ${params.truseq_r2}"
    }
    else if (params.adapter == 'nextera'){
      adapter ="--adapter_sequence ${params.nextera_r1} --adapter_sequence_r2 ${params.nextera_r2}"
    }
    """
    fastp --version &> v_fastp.txt 2>&1 || true
    fastp ${adapter} \
    --qualified_quality_phred ${params.qualtrim} \
    ${nextseq_trim} ${pico_opts} ${polyA_opts} ${lig_opts} \
    ${ntrim} \
    --length_required ${params.minlen} \
    -i ${reads[0]} -I ${reads[1]} -o ${prefix}_trimmed_R1.fastq.gz -O ${prefix}_trimmed_R2.fastq.gz \
    --detect_adapter_for_pe -j ${prefix}.fastp.json -h ${prefix}.fastp.html \
    --thread ${task.cpus} 2> ${prefix}_fasp.log
    """
  }
}


if (!params.skip_trimming){
  if(params.trimtool == "atropos"){
    trim_reads = trim_reads_atropos
    trim_reports = report_results_atropos
  }else if (params.trimtool == "trimgalore"){
    trim_reads = trim_reads_trimgalore
    trim_reports = report_results_trimgalore
  }else if (params.trimtool == "fastp"){
    trim_reads = trim_reads_fastp
    trim_reports = report_results_fastp
  }
}

/*
================================================================================
                                   Make Reports
================================================================================
*/


if (!params.skip_trimming){

  //rawdata_report = Channel.empty()

  process makeReport {
    label 'python'
    label 'lowCpu'
    label 'extraMem'
    publishDir "${params.outdir}/makeReport", mode: 'copy'

    when:
    !params.skip_trimming

    input:
    set val(name), file(reads), file(trims), file(reports) from read_files_trimreport.join(trim_reads).join(trim_reports)

    output:
    file '*_Basic_Metrics.trim.txt' into trim_report
    file "*_Adaptor_seq.trim.txt" into trim_adaptor
    script:
    prefix = reads[0].toString() - ~/(_1)?(_2)?(_R1)?(_R2)?(.R1)?(.R2)?(_val_1)?(_val_2)?(\.fq)?(\.fastq)?(\.gz)?$/
    isPE = params.singleEnd ? 0 : 1
    if (params.singleEnd) {
      if(params.trimtool == "fastp"){
      """
      create_subset_data.sh ${isPE} ${prefix} ${reads} ${trims}
      trimming_report.py --l ${prefix}_fasp.log --tr1 ${reports[0]} --r1 subset_${prefix}.R1.fastq.gz --t1 subset_${prefix}_trims.R1.fastq.gz --u ${params.trimtool} --b ${name} --o ${prefix}
      """
      } else {
      """
      create_subset_data.sh ${isPE} ${prefix} ${reads} ${trims}
      trimming_report.py --tr1 ${reports} --r1 subset_${prefix}.R1.fastq.gz --t1 subset_${prefix}_trims.R1.fastq.gz --u ${params.trimtool} --b ${name} --o ${prefix}
      """
      }
    } else {
      if(params.trimtool == "trimgalore"){
      """
      create_subset_data.sh ${isPE} ${prefix} ${reads} ${trims}
      trimming_report.py --tr1 ${reports[0]} --tr2 ${reports[1]} --r1 subset_${prefix}.R1.fastq.gz --r2 subset_${prefix}.R2.fastq.gz --t1 subset_${prefix}_trims.R1.fastq.gz --t2 subset_${prefix}_trims.R2.fastq.gz --u ${params.trimtool} --b ${name} --o ${prefix}
      """
      } else if (params.trimtool == "fastp"){
      """
      create_subset_data.sh ${isPE} ${prefix} ${reads} ${trims}
      trimming_report.py --l ${prefix}_fasp.log --tr1 ${reports[0]} --r1 subset_${prefix}.R1.fastq.gz --r2 subset_${prefix}.R2.fastq.gz --t1 subset_${prefix}_trims.R1.fastq.gz --t2 subset_${prefix}_trims.R2.fastq.gz --u ${params.trimtool} --b ${name} --o ${prefix}
      """
      } else {
      """
      create_subset_data.sh ${isPE} ${prefix} ${reads} ${trims}
      trimming_report.py --tr1 ${reports[0]} --r1 subset_${prefix}.R1.fastq.gz --r2 subset_${prefix}.R2.fastq.gz --t1 subset_${prefix}_trims.R1.fastq.gz --t2 subset_${prefix}_trims.R2.fastq.gz --u ${params.trimtool} --b ${name} --o ${prefix}
      """
      }
    }
  }
}else{

  trim_adaptor = Channel.empty()

  process makeReport4RawData {
    label 'python'
    label 'lowCpu'
    label 'extraMem'
    publishDir "${params.outdir}/makeReport", mode: 'copy'

    input:
    set val(name), file(reads) from read_files_rawdatareport

    output:
    file '*_Basic_Metrics_rawdata.txt' into trim_report

    script:
    prefix = reads[0].toString() - ~/(_1)?(_2)?(_R1)?(_R2)?(.R1)?(.R2)?(_val_1)?(_val_2)?(\.fq)?(\.fastq)?(\.gz)?$/
    if (params.singleEnd) {
     """
     rawdata_stat_report.py --r1 ${reads} --b ${name} --o ${prefix}
     """
    } else {
     """
     rawdata_stat_report.py --r1 ${reads[0]} --r2 ${reads[1]} --b ${name} --o ${prefix}
     """
    }
  }
}

/*
================================================================================
                                     QC on trim data [FastQC]
================================================================================
*/


if (!params.skip_trimming){
  if (params.trimtool == "atropos"){
    atropos_reads.into{fastqc_trim_reads; fastq_screen_reads} 
  }else if (params.trimtool == "trimgalore"){
    trimgalore_reads.into{fastqc_trim_reads; fastq_screen_reads}
  }else{
    fastp_reads.into{fastqc_trim_reads; fastq_screen_reads}
  }
}else{
  fastq_screen_reads = read_fastqscreen  
  fastqc_trim_reads = Channel.empty()
}


if (!params.skip_fastqc_trim && !params.skip_trimming){


process fastqcTrimmed {
   label 'fastqc'
   label 'lowCpu'
   label 'minMem'
   publishDir "${params.outdir}/fastqc_trimmed", mode: 'copy'


    input:
    set val(name), file(reads) from fastqc_trim_reads

    output:
    file "*_fastqc.{zip,html}" into fastqc_after_trim_results
    file("v_fastqc.txt") into fastqctrimmed_version

    script:
    """
    fastqc -q $reads -t ${task.cpus}
    fastqc --version &> v_fastqc.txt 2>&1 || true
    """
  }
}else{
  fastqc_after_trim_results = Channel.empty()
}

/*
================================================================================
                                     FastqScreen
================================================================================
*/

process makeFastqScreenGenomeConfig {
    label 'lowCpu'
    label 'extraMem'
    publishDir "${params.outdir}/fastq_screen", mode: 'copy'
   
    
    when:
    !params.skip_fastq_screen

    input:
    val(fastqScreenGenome) from fastqScreenGenomeCh

    output:
    file(outputFile) into ch_fastq_screen_config

    script:
    outputFile = 'fastq_screen_databases.config'

    String result = ''
    for (Map.Entry entry: fastqScreenGenome.entrySet()) {
        result += """
        echo -e 'DATABASE\\t${entry.key}\\t${entry.value}' >> ${outputFile}"""
    }

    return result
}

process fastqScreen {
   label 'fastqScreen'
   label 'lowCpu'
   label 'extraMem'
   publishDir "${params.outdir}/fastq_screen", mode: 'copy'


   when:
   !params.skip_fastq_screen

   input:
   file fastqScreenGenomes from Channel.fromList(params.genomes.fastqScreenGenomes.values().collect{file(it)})
   set val(name), file(reads) from fastq_screen_reads
   file fastq_screen_config from ch_fastq_screen_config.collect()

   output:
   file("*_screen.txt") into fastq_screen_txt
   file("*_screen.html") into fastq_screen_html
   file("*tagged_filter.fastq.gz") into nohits_fastq
   file("v_fastqscreen.txt") into fastqscreen_version

   script:
   """
   fastq_screen --force --subset 200000 --threads ${task.cpus} --conf ${fastq_screen_config} --nohits --aligner bowtie2 ${reads}
   fastq_screen --version &> v_fastqscreen.txt 2>&1 || true
   """
}

/*
================================================================================
                                     MultiQC
================================================================================
*/

/*
 * Parse software version numbers
 * @output software_versions_mqc.yaml
 */

/*
 * MulitQC report
*/
process get_software_versions {
  label 'python'
  label 'minCpu'
  label 'minMem'

  publishDir path:"${params.outdir}/softwareVersions", mode: 'copy'

  input:
  file('v_trimgalore.txt') from trimgalore_version.first().ifEmpty([])
  file('v_fastp.txt') from fastp_version.first().ifEmpty([])
  file('v_atropos.txt') from atropos_version.first().ifEmpty([])
  file('v_fastqscreen.txt') from fastqscreen_version.first().ifEmpty([])
  file('v_fastqc.txt') from fastqc_version.mix(fastqctrimmed_version).first().ifEmpty([])

  output:
  file('software_versions_mqc.yaml') into software_versions_yaml

  script:
  """
  echo "${workflow.manifest.version}" &> v_pipeline.txt 2>&1 || true
  echo "${workflow.nextflow.version}" &> v_nextflow.txt 2>&1 || true
  scrape_software_versions.py &> software_versions_mqc.yaml
  """
}

process workflow_summary_mqc {
  when:
  !params.skip_multiqc

  output:
  file 'workflow_summary_mqc.yaml' into workflow_summary_yaml

  exec:
  def yaml_file = task.workDir.resolve('workflow_summary_mqc.yaml')
  yaml_file.text  = """
  id: 'summary'
  description: " - this information is collected when the pipeline is started."
  section_name: 'Workflow Summary'
  section_href: 'https://gitlab.curie.fr/rawqc'
  plot_type: 'html'
  data: |
      <dl class=\"dl-horizontal\">
${summary.collect { k,v -> "            <dt>$k</dt><dd><samp>${v ?: '<span style=\"color:#999999;\">N/A</a>'}</samp></dd>" }.join("\n")}
      </dl>
  """.stripIndent()
}

/*
 *  MultiQC
 */

process multiqc {
  label 'multiqc'
  label 'minCpu'
  label 'minMem'
  publishDir "${params.outdir}/MultiQC", mode: 'copy'

  when:
  !params.skip_multiqc

  input:
  file splan from ch_splan.collect()
  file metadata from ch_metadata.ifEmpty([])
  file multiqc_config from ch_multiqc_config
  file (fastqc:'fastqc/*') from fastqc_results.collect().ifEmpty([]) 
  file ('atropos/*') from trim_results_atropos.collect().ifEmpty([])
  file ('trimGalore/*') from trim_results_trimgalore.map{items->items[1]}.collect().ifEmpty([])
  file ('fastp/*') from trim_results_fastp.map{items->items[1]}.collect().ifEmpty([])
  file (fastqc:'fastqc_trimmed/*') from fastqc_after_trim_results.collect().ifEmpty([])
  file ('fastq_screen/*') from fastq_screen_txt.collect().ifEmpty([])
  file ('makeReport/*') from trim_report.collect().ifEmpty([])
  file ('makeReport/*') from trim_adaptor.collect().ifEmpty([])
  //file ('makeReport/*') from rawdata_report.collect().ifEmpty([])
  file ('software_versions/*') from software_versions_yaml.collect()
  file ('workflow_summary/*') from workflow_summary_yaml.collect()

  
  output:
  file splan
  file "*_report.html" into multiqc_report
  file "*_data"
  file("v_multiqc.txt") into multiqc_version

  script:
  rtitle = custom_runName ? "--title \"$custom_runName\"" : ''
  rfilename = custom_runName ? "--filename " + custom_runName + "_rawqc_report" : '--filename rawqc_report'
  isPE = params.singleEnd ? 0 : 1
  isSkipTrim = params.skip_trimming ? 0 : 1
  metadata_opts = params.metadata ? "--metadata ${metadata}" : ""
  splan_opts = params.samplePlan ? "--splan ${params.samplePlan}" : ""

  """
  multiqc --version &> v_multiqc.txt 2>&1 || true
  mqc_header.py --name "Raw-QC" --version ${workflow.manifest.version} ${metadata_opts} ${splan_opts} > multiqc-config-header.yaml
  stats2multiqc.sh ${isPE} ${isSkipTrim}
  multiqc . -f $rtitle $rfilename -c $multiqc_config -c multiqc-config-header.yaml -m custom_content -m cutadapt -m fastqc -m fastp -m fastq_screen
  """
}

