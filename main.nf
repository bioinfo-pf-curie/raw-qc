#!/usr/bin/env nextflow

/*
Copyright Institut Curie 2019
This software is a computer program whose purpose is to analyze high-throughput sequencing data.
You can use, modify and/ or redistribute the software under the terms of license (see the LICENSE file for more details).
The software is distributed in the hope that it will be useful, but "AS IS" WITHOUT ANY WARRANTY OF ANY KIND. 
Users are therefore encouraged to test the software's suitability as regards their requirements in conditions enabling the security of their systems and/or data. 
The fact that you are presently reading this means that you have had knowledge of the license and that you accept its terms.

This script is based on the nf-core guidelines. See https://nf-co.re/ for more information
*/


/*
========================================================================================
                         Raw-QC
========================================================================================
 Raw QC Pipeline.
 #### Homepage / Documentation
 https://gitlab.curie.fr/raw-qc
----------------------------------------------------------------------------------------
*/


def helpMessage() {
    log.info"""
    raw-qc v${workflow.manifest.version}
    =======================================================

    Usage:
    nextflow run main.nf --reads '*_R{1,2}.fastq.gz' -profile conda
    nextflow run main.nf --samplePlan sample_plan -profile conda


    Mandatory arguments:
      --reads                       Path to input data (must be surrounded with quotes)
      --samplePlan                  Path to sample plan input file (cannot be used with --reads)
      -profile                      Configuration profile to use. test / curie / conda / docker / singularity / cluster (see below)

    Options:
      --singleEnd                   Specifies that the input is single end reads
      --trimtool                    Specifies adapter trimming tool ['trimgalore', 'atropos', 'fastp']. Default is 'trimgalore'.

    Trimming options:
      --adapter                     Type of adapter to trim ['auto', 'truseq', 'nextera', 'smallrna']. Default is 'auto' for automatic detection
      --qualtrim                    Minimum mapping quality for trimming. Default is '0', ie. no quality trimming
      --ntrim                       Trim 'N' bases from either side of the reads
      --two_colour                     Trimming for NextSeq/NovaSeq sequencers
      --minlen                      Minimum length of trimmed sequences

    Presets:
      --pico                        Sets trimming settings for the SMARTer Stranded Total RNA-Seq Kit - Pico Input kit. Only for trimgalore and fastp.

    Other options:
      --skip_fastqc_raw             Skip FastQC on raw sequencing reads
      --skip_trimming               Skip trimming step
      --skip_fastqc_trim            Skip FastQC on trimmed sequencing reads
      --outdir                      The output directory where the results will be saved
      --email                       Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits
      -name                         Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.

    """.stripIndent()
}

/*
 * SET UP CONFIGURATION VARIABLES
 */

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
if (params.trimtool!= 'trimgalore' && params.trimtool != 'atropos' && params.trimtool != 'fastp' ){
    exit 1, "Invalid trimming tool option: ${params.trimtool}. Valid options: 'trimgalore', 'atropos', 'fastp'"
} 

if (params.adapter!= 'truseq' && params.adapter != 'nextera' && params.adapter != 'smallrna' && params.adapter!= 'auto' ){
    exit 1, "Invalid adaptator seq tool option: ${params.adapter}. Valid options: 'truseq', 'nextera', 'smallrna', 'auto'"
}

if (params.adapter == 'smallrna' && !params.singleEnd){
    exit 1, "${params.adapter} is only for singleEnd data. "
}

if (params.ntrim && params.trimtool == 'fastp') {
  log.warn "[raw-qc] The 'ntrim' option is not availabe for the 'fastp' trimmer. Option is ignored."
}

if ( params.pico && params.trimtool == 'atropos' ){
    exit 1, "Cannot use Atropos for pico preset"
}

// Stage config files
ch_multiqc_config = Channel.fromPath(params.multiqc_config)
ch_output_docs = Channel.fromPath("$baseDir/docs/output.md")
ch_adaptor_file_detect = Channel.fromPath("$baseDir/assets/sequencing_adapters.fa")
ch_adaptor_file_defult = Channel.fromPath("$baseDir/assets/sequencing_adapters.fa")

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
         .into { read_files_fastqc; read_files_trimgalore; read_files_atropos_detect; read_files_atropos_trim; read_files_fastp; read_files_trimreport }
   }else{
      Channel
         .from(file("${params.samplePlan}"))
         .splitCsv(header: false)
         .map{ row -> [ row[1], [file(row[2]), file(row[3])]] }
         .into { read_files_fastqc; read_files_trimgalore; read_files_atropos_detect; read_files_atropos_trim; read_files_fastp; read_files_trimreport }
   }
   params.reads=false
}
else if(params.readPaths){
    if(params.singleEnd){
        Channel
            .from(params.readPaths)
            .map { row -> [ row[0], [file(row[1][0])]] }
            .ifEmpty { exit 1, "params.readPaths was empty - no input files supplied" }
            .into { read_files_fastqc; read_files_trimgalore; read_files_atropos_detect; read_files_atropos_trim; read_files_fastp; read_files_trimreport }
    } else {
        Channel
            .from(params.readPaths)
            .map { row -> [ row[0], [file(row[1][0]), file(row[1][1])]] }
            .ifEmpty { exit 1, "params.readPaths was empty - no input files supplied" }
            .into { read_files_fastqc; read_files_trimgalore; read_files_atropos_detect; read_files_atropos_trim; read_files_fastp; read_files_trimreport }
    }
} else {
    Channel
        .fromFilePairs( params.reads, size: params.singleEnd ? 1 : 2 )
        .ifEmpty { exit 1, "Cannot find any reads matching: ${params.reads}\nNB: Path needs to be enclosed in quotes!\nNB: Path requires at least one * wildcard!\nIf this is single-end data, please specify --singleEnd on the command line\
." }
        .into { read_files_fastqc; read_files_trimgalore; read_files_atropos_detect; read_files_atropos_trim; read_files_fastp; read_files_trimreport }
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


// Header log info
log.info """=======================================================

raw-qc v${workflow.manifest.version}"
======================================================="""
def summary = [:]
summary['Pipeline Name']  = 'rawqc'
summary['Pipeline Version'] = workflow.manifest.version
summary['Run Name']     = custom_runName ?: workflow.runName
if (params.samplePlan) {
   summary['SamplePlan']   = params.samplePlan
}else{
   summary['Reads']        = params.reads
}
summary['Data Type']    = params.singleEnd ? 'Single-End' : 'Paired-End'
summary['Trimming tool']= params.trimtool
summary['Max Memory']   = params.max_memory
summary['Max CPUs']     = params.max_cpus
summary['Max Time']     = params.max_time
summary['Container Engine'] = workflow.containerEngine
if(workflow.containerEngine) summary['Container'] = workflow.container
summary['Current home']   = "$HOME"
summary['Current user']   = "$USER"
summary['Current path']   = "$PWD"
summary['Working dir']    = workflow.workDir
summary['Output dir']     = params.outdir
summary['Script dir']     = workflow.projectDir
summary['Config Profile'] = workflow.profile

if(params.email) summary['E-mail Address'] = params.email
log.info summary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "========================================="


/*
 * STEP 1 - FastQC
*/


process fastqc {
    tag "$name (raw)"
    //conda 'fastqc=0.11.8'
    publishDir "${params.outdir}/fastqc", mode: 'copy',
        saveAs: {filename -> filename.indexOf(".zip") > 0 ? "zips/$filename" : "$filename"}

    when:
    !params.skip_fastqc_raw

    input:
    set val(name), file(reads) from read_files_fastqc

    output:
    file "*_fastqc.{zip,html}" into fastqc_results

    script:
    """
    fastqc -q $reads -t ${task.cpus}
    """
}

/*
 * STEP 2 - Reads Trimming
*/

process trimGalore {
  tag "$name" 

  //conda 'trim-galore=0.6.2'
  publishDir "${params.outdir}/trimming", mode: 'copy',
              saveAs: {filename -> filename.indexOf(".log") > 0 ? "logs/$filename" : "$filename"}
  when:
  params.trimtool == "trimgalore" && !params.skip_trimming

  input:
  set val(name), file(reads) from read_files_trimgalore

  output:
  file "*fq.gz" into trim_reads_trimgalore, fastqc_trimgalore_reads
  file "*trimming_report.txt" into trim_results_trimgalore

  script:
  prefix = reads[0].toString() - ~/(_1)?(_2)?(_R1)?(_R2)?(.R1)?(.R2)?(_val_1)?(_val_2)?(\.fq)?(\.fastq)?(\.gz)?$/
  ntrim = params.ntrim > 0 ? "--trim-n" : ""
  qual_trim = params.two_colour ?  "--two_colour ${params.qualtrim}" : "--quality ${params.qualtrim}"
  pico_ots = params.pico ? "--clip_r1 3 --clip_r2 0 --three_prime_clip_r1 0 --three_prime_clip_r2 3" : ""
  adapter=""

  if (params.singleEnd) {
    if (params.adapter == 'truseq'){
      adapter = "--adapter ${params.truseq_r1}"
    }else if (params.adapter == 'nextera'){
      adapter = "--adapter ${params.nextera_r1}"
    }else if (params.adapter == 'smallrna'){
      adapter = "--adapter ${params.smallrna_r1}"
    }
    """
    trim_galore ${adapter} \
                ${ntrim} \
                ${nextseq_trim} \
                --length ${params.minlen} \
                ${pico_opts} \
                --gzip $reads --basename ${prefix} --cores ${task.cpus}
    """
  }else {
    if (params.adapter == 'truseq'){
      adapter ="--adapter ${params.truseq_r1} --adapter2 ${params.truseq_r2}"
    }else if (params.adapter == 'nextera'){
      adapter ="--adapter ${params.nextera_r1} --adapter2 ${params.nextera_r2}"
    }
    """
    trim_galore ${adapter} \
                ${qualtrim} \
                ${ntrim} \
                ${qual_trim} \
                --length ${params.minlen} \
                ${pico_opts} \
                --paired --gzip $reads --basename ${prefix} --cores ${task.cpus}
    mv ${prefix}_R1_val_1.fq.gz ${prefix}_R1_trimmed.fq.gz
    mv ${prefix}_R2_val_2.fq.gz ${prefix}_R2_trimmed.fq.gz
    """
  }
}


process atroposDetect {
  tag "$name"

  publishDir "${params.outdir}/trimming", mode: 'copy',
              saveAs: {filename -> filename.indexOf(".log") > 0 ? "logs/$filename" : "$filename"}

  when:
  params.trimtool =="atropos" && params.adapter == 'auto' && !params.skip_trimming
 
  input:
  set val(name), file(reads) from read_files_atropos_detect
  file sequences from ch_adaptor_file_detect.collect()

  output:
  file "*.fasta" into detected_adapters_atropos

  script:
  prefix = reads[0].toString() - ~/(_1)?(_2)?(_R1)?(_R2)?(.R1)?(.R2)?(_val_1)?(_val_2)?(\.fq)?(\.fastq)?(\.gz)?$/

  // see here for options: vi /data/kdi_prod/project_result/1408/01.00/svn/analyse/script/scripts/atropos_script_2003528.sh
  // see here for results: /data/kdi_prod/project_result/1408/01.00/svn/analyse/script/PLASMA-NIVO/atropos/A705L12_detect
  if ( params.singleEnd ){
  """
  atropos detect --max-read 100000 \
                 --detector 'known' \
  	  	 -se ${reads} \
		 -F ${sequences} \
                 -o ${prefix}_detect \
		 --include-contaminants 'known' \
                 --output-formats 'fasta' \
		 --log-file ${prefix}_atropos.log
  """
  }else{
  """
  atropos detect --max-read 100000 \
                 --detector 'known' \
                 -pe1 ${reads[0]} -pe2 ${reads[1]} \
		 -F ${sequences} \
                 -o ${prefix}_detect \
                 --include-contaminants 'known' \
                 --output-formats 'fasta' \
                 --log-file ${prefix}_atropos.log
  """
  }
}

process atroposTrim {
  tag "$name"

  //conda 'atropos=1.1.16'
  publishDir "${params.outdir}/trimming", mode: 'copy',
              saveAs: {filename -> filename.indexOf(".log") > 0 ? "logs/$filename" : "$filename"}
  
  when:
  params.trimtool == "atropos" && !params.skip_trimming
  
  input:
  set val(name), file(reads) from read_files_atropos_trim
  file adapters from detected_adapters_atropos.collect()
  file sequences from ch_adaptor_file_defult.collect()

  output:
  file "*trimming_report*" into trim_results_atropos
  file "*_trimmed.fq.gz" into trim_reads_atropos, fastqc_atropos_reads

   script:
   prefix = reads[0].toString() - ~/(_1)?(_2)?(_R1)?(_R2)?(.R1)?(.R2)?(_val_1)?(_val_2)?(\.fq)?(\.fastq)?(\.gz)?$/
   ntrim = params.ntrim ? "--trim_n" : ""
   nextseq_trim = params.two_colour ? "--nextseq-trim" : ""
   adapter=""

   if (params.singleEnd) {
     if (params.adapter == 'truseq'){
       adapter ="--adapter ${params.truseq_r1}"
     }else if (params.adapter == 'nextera'){
       adapter ="--adapter ${params.nextera_r1}"
     }else if (params.adapter == 'smallrna'){
       adapter ="--adapter ${params.smallrna_r1}"
     }else if (params.adapter == 'auto'){
       adapter="--adapter file:${prefix}_detect.0.fasta"
     }
     """
     readcount=`cat ${prefix}_detect.0.fasta|wc -l`
     if [ \$readcount != '0' ]
     then
       atropos trim -se ${reads} ${adapter} \
         --minimum-length ${params.minlen} \
         -q ${params.qualtrim} \
         ${ntrim} \
         ${nextseq_trim} \
         --threads ${task.cpus} \
         -o ${prefix}_trimmed.fq.gz \
         --report-file ${prefix}_trimming_report.txt \
         --info-file ${prefix}_trimming_info.txt \
         --report-formats 'json' 'yaml' --stats 'both'
     else    
       cp ${reads} ${prefix}_trimmed.fq.gz
       touch ${prefix}_trimming_report.txt.json
       touch ${prefix}_trimming_report.txt.yaml
     fi
     """
   } else {
     if (params.adapter == 'truseq'){
       adapter ="--adapter ${params.truseq_r1} -A ${params.truseq_r2}"
     }else if (params.adapter == 'nextera'){
       adapter ="--adapter ${params.nextera_r1} -A ${params.nextera_r2}"
     }else{
       adapter="--adapter file:${prefix}_detect.0.fasta -A file:${prefix}_detect.1.fasta"
     }
     """
     readcount0=`cat ${prefix}_detect.0.fasta|wc -l`
     readcount1=`cat ${prefix}_detect.1.fasta|wc -l`
     if [ \$readcount0 != '0' ] && [ \$readcount1 != '0' ]
     then
       atropos ${adapters}  -pe1 ${reads[0]} -pe2 ${reads[1]}\
         -o ${prefix}_R1_trimmed.fq.gz -p ${prefix}_R2_trimmed.fq.gz  \
         --minimum-length ${params.minlen} \
         -q ${params.qualtrim} \
         ${ntrim} \
         ${nextseq_trim} \
         --threads ${task.cpus} \
         --report-file ${prefix}_trimming_report \
         --info-file ${prefix}_trimming_info.txt \
         --report-formats 'json' 'yaml' --stats 'both'
     else
       cp ${reads[0]} ${prefix}_R1_trimmed.fq.gz
       cp ${reads[1]} ${prefix}_R2_trimmed.fq.gz
       touch ${prefix}_trimming_report.txt.json
       touch ${prefix}_trimming_report.txt.yaml
     fi
   """
   }
}

process fastp {
  tag "$name"
 
  publishDir "${params.outdir}/trimming", mode: 'copy',
              saveAs: {filename -> filename.indexOf(".log") > 0 ? "logs/$filename" : "$filename"}

  when:
  params.trimtool == "fastp" && !params.skip_trimming
  
  input:
  set val(name), file(reads) from read_files_fastp
  
  output:
  file "*_trimmed.fastq.gz" into trim_reads_fastp, fastqc_fastp_reads
  file "*.json" into trim_results_fastp
  file "*.log" into trim_log_fastp

  script:
  prefix = reads[0].toString() - ~/(_1)?(_2)?(_R1)?(_R2)?(.R1)?(.R2)?(_val_1)?(_val_2)?(\.fq)?(\.fastq)?(\.gz)?$/
  nextseq_trim = params.two_colour ? "--trim_poly_g" : "--disable_trim_poly_g"
  pico_ots = params.pico ? "--trim_front1 3 --trim_front2 0 --trim_tail1 0 --trim_tail2 3" : ""
  adapter=""

  if (params.singleEnd) {
    if (params.adapter == 'truseq'){
      adapter ="--adapter_sequence ${params.truseq_r1}"
    }else if (params.adapter == 'nextera'){
      adapter ="--adapter_sequence ${params.nextera_r1}"
    }else if (params.adapter == 'smallrna'){
      adapter ="--adapter_sequence ${params.smallrna_r1}"
    }
    """
    fastp ${adapter} \
    --qualified_quality_phred ${params.qualtrim} \
    ${nextseq_trim} \
    ${pico_opts} \
    --length_required ${params.minlen} \
    -i ${reads} \
    -o ${prefix}_trimmed.fastq.gz \
    -j ${prefix}.fastp.json -h ${prefix}.fastp.html\
    --thread ${task.cpus} 2> ${prefix}_fasp.log
    """
  } else {
    if (params.adapter == 'truseq'){
      adapter ="--adapter_sequence ${params.truseq_r1} --adapter_sequence_r2 ${params.truseq_r2}"
    }else if (params.adapter == 'nextera'){
      adapter ="--adapter_sequence ${params.nextera_r1} --adapter_sequence_r2 ${params.nextera_r2}"
    }
    """
    fastp ${adapter} \
     --qualified_quality_phred ${params.qualtrim} \
     ${nextseq_trim} \
     ${pico_opts} \
    --length_required ${params.minlen} \
    -i ${reads[0]} -I ${reads[1]} \
    -o ${prefix}_R1_trimmed.fastq.gz -O ${prefix}_R2_trimmed.fastq.gz \
    --detect_adapter_for_pe \
    -j ${prefix}.fastp.json -h ${prefix}.fastp.html \
    --thread ${task.cpus} 2> ${prefix}_fasp.log
    """
  }
}

if(params.trimtool == "atropos"){
  trim_reads = trim_reads_atropos.collect()
}else if (params.trimtool == "trimgalore"){
  trim_reads = trim_reads_trimgalore.collect()
}else{
  trim_reads = trim_reads_fastp.collect()
}

process trimReport {

  //conda 'python=3.6'
  publishDir "${params.outdir}/trimReport", mode: 'copy',
              saveAs: {filename -> filename.indexOf(".log") > 0 ? "logs/$filename" : "$filename"}

  when:
  !params.skip_trimming

  input:
  set val(name), file(reads) from read_files_trimreport
  file trims from trim_reads

  output:
  file "*_Basic_Metrics.trim.txt" into trim_report

  script:
  prefix = reads[0].toString() - ~/(_1)?(_2)?(_R1)?(_R2)?(.R1)?(.R2)?(_val_1)?(_val_2)?(\.fq)?(\.fastq)?(\.gz)?$/
  if (params.singleEnd) {
  """
  TrimReport.py --r1 ${reads} --t1 ${trims} --o ${prefix}_Basic_Metrics
  """
  } else {
  """
  TrimReport.py --r1 ${reads[0]} --r2 ${reads[1]} --t1 ${trims[0]} --t2 ${trims[1]} --o ${prefix}_Basic_Metrics
  """
  }
}

/*
 * STEP 3 - FastQC after Trim!
*/
if(params.trimtool == "atropos"){
  fastqc_trim_reads = fastqc_atropos_reads
}else if (params.trimtool == "trimgalore"){
  fastqc_trim_reads = fastqc_trimgalore_reads
}else{
  fastqc_trim_reads = fastqc_fastp_reads
}
 
process fastqcTrimmed {
  tag "$name (trimmed reads)"
  //conda 'fastqc=0.11.8'

  publishDir "${params.outdir}/fastqc_trimmed", mode: 'copy',
      saveAs: {filename -> filename.indexOf(".zip") > 0 ? "zips/$filename" : "$filename"}

  when:
  !params.skip_fastqc_trim

  input:
  file reads from fastqc_trim_reads

  output:
  file "*_fastqc.{zip,html}" into fastqc_after_trim_results

  script:
  """
  fastqc -q $reads -t ${task.cpus}
  """
}

/*
 * MultiQC
 */

process get_software_versions {
  output:
  file 'software_versions_mqc.yaml' into software_versions_yaml

  script:
  """
  echo $workflow.manifest.version &> v_rnaseq.txt
  echo $workflow.nextflow.version &> v_nextflow.txt
  fastqc --version &> v_fastqc.txt
  STAR --version &> v_star.txt
  tophat2 --version &> v_tophat2.txt
  hisat2 --version &> v_hisat2.txt
  preseq &> v_preseq.txt
  infer_experiment.py --version &> v_rseqc.txt
  read_duplication.py --version &> v_read_duplication.txt
  featureCounts -v &> v_featurecounts.txt
  htseq-count -h | grep version  &> v_htseq.txt
  picard MarkDuplicates --version &> v_markduplicates.txt  || true
  samtools --version &> v_samtools.txt
  multiqc --version &> v_multiqc.txt
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
  section_href: 'https://gitlab.curie.fr/rnaseq'
  plot_type: 'html'
  data: |
      <dl class=\"dl-horizontal\">
${summary.collect { k,v -> "            <dt>$k</dt><dd><samp>${v ?: '<span style=\"color:#999999;\">N/A</a>'}</samp></dd>" }.join("\n")}
      </dl>
  """.stripIndent()
}

process multiqc {
  publishDir "${params.outdir}/MultiQC", mode: 'copy'
  //conda 'multiqc'

  input:
  file splan from ch_splan.collect()
  file multiqc_config from ch_multiqc_config
  file (fastqc:'fastqc/*') from fastqc_results.collect().ifEmpty([]) 
  file ('atropos/*') from trim_results_atropos.collect().ifEmpty([])
  file ('trimGalore/*') from trim_results_trimgalore.collect().ifEmpty([])
  file ('fastp/*') from trim_results_fastp.collect().ifEmpty([])
  file (fastqc:'fastqc_trimmed/*') from fastqc_after_trim_results.collect().ifEmpty([])
  file ('trimReport/*') from trim_report.collect().ifEmpty([])
  
  output:
  file splan
  file "*rawqc_report.html" into multiqc_report
  file "*_data"

  custom_runName=custom_runName ?: workflow.runName
  script:
  rtitle = custom_runName ? "--title \"$custom_runName\"" : ''
  rfilename = custom_runName ? "--filename " + custom_runName.replaceAll('\\W','_').replaceAll('_+','_') + "_multiqc_report" : ''
  """
  multiqc . -f $rtitle $rfilename --config $multiqc_config -m custom_content -m cutadapt -m fastqc -m fastp
  """
}


/*
 * Sub-routine
 */
process output_documentation {
    publishDir "${params.outdir}/pipeline_info", mode: 'copy'

    input:
    file output_docs from ch_output_docs

    output:
    file "results_description.html"

    script:
    """
    markdown_to_html.r $output_docs results_description.html
    """
}

workflow.onComplete {

    // Set up the e-mail variables
    def subject = "[rnaseq] Successful: $workflow.runName"
    if(skipped_poor_alignment.size() > 0){
        subject = "[rnaseq] Partially Successful (${skipped_poor_alignment.size()} skipped): $workflow.runName"
    }
    if(!workflow.success){
      subject = "[rnaseq] FAILED: $workflow.runName"
    }
    def email_fields = [:]
    email_fields['version'] = workflow.manifest.version
    email_fields['runName'] = custom_runName ?: workflow.runName
    email_fields['success'] = workflow.success
    email_fields['dateComplete'] = workflow.complete
    email_fields['duration'] = workflow.duration
    email_fields['exitStatus'] = workflow.exitStatus
    email_fields['errorMessage'] = (workflow.errorMessage ?: 'None')
    email_fields['errorReport'] = (workflow.errorReport ?: 'None')
    email_fields['commandLine'] = workflow.commandLine
    email_fields['projectDir'] = workflow.projectDir
    email_fields['summary'] = summary
    email_fields['summary']['Date Started'] = workflow.start
    email_fields['summary']['Date Completed'] = workflow.complete
    email_fields['summary']['Pipeline script file path'] = workflow.scriptFile
    email_fields['summary']['Pipeline script hash ID'] = workflow.scriptId
    if(workflow.repository) email_fields['summary']['Pipeline repository Git URL'] = workflow.repository
    if(workflow.commitId) email_fields['summary']['Pipeline repository Git Commit'] = workflow.commitId
    if(workflow.revision) email_fields['summary']['Pipeline Git branch/tag'] = workflow.revision
    if(workflow.container) email_fields['summary']['Docker image'] = workflow.container
    email_fields['skipped_poor_alignment'] = skipped_poor_alignment

    // On success try attach the multiqc report
    def mqc_report = null
    try {
        if (workflow.success && !params.skip_multiqc) {
            mqc_report = multiqc_report.getVal()
            if (mqc_report.getClass() == ArrayList){
                log.warn "[rnaseq] Found multiple reports from process 'multiqc', will use only one"
                mqc_report = mqc_report[0]
                }
        }
    } catch (all) {
        log.warn "[rnaseq] Could not attach MultiQC report to summary email"
    }

    // Render the TXT template
    def engine = new groovy.text.GStringTemplateEngine()
    def tf = new File("$baseDir/assets/email_template.txt")
    def txt_template = engine.createTemplate(tf).make(email_fields)
    def email_txt = txt_template.toString()

    // Render the HTML template
    def hf = new File("$baseDir/assets/email_template.html")
    def html_template = engine.createTemplate(hf).make(email_fields)
    def email_html = html_template.toString()

    // Render the sendmail template
    def smail_fields = [ email: params.email, subject: subject, email_txt: email_txt, email_html: email_html, baseDir: "$baseDir", mqcFile: mqc_report, mqcMaxSize: params.maxMultiqcEmailFileSize.toBytes() ]
    def sf = new File("$baseDir/assets/sendmail_template.txt")
    def sendmail_template = engine.createTemplate(sf).make(smail_fields)
    def sendmail_html = sendmail_template.toString()

    // Send the HTML e-mail
    if (params.email) {
        try {
          if( params.plaintext_email ){ throw GroovyException('Send plaintext e-mail, not HTML') }
          // Try to send HTML e-mail using sendmail
          [ 'sendmail', '-t' ].execute() << sendmail_html
          log.info "[rnaseq] Sent summary e-mail to $params.email (sendmail)"
        } catch (all) {
          // Catch failures and try with plaintext
          [ 'mail', '-s', subject, params.email ].execute() << email_txt
          log.info "[rnaseq] Sent summary e-mail to $params.email (mail)"
        }
    }

    // Write summary e-mail HTML to a file
    def output_d = new File( "${params.outdir}/pipeline_info/" )
    if( !output_d.exists() ) {
      output_d.mkdirs()
    }
    def output_hf = new File( output_d, "pipeline_report.html" )
    output_hf.withWriter { w -> w << email_html }
    def output_tf = new File( output_d, "pipeline_report.txt" )
    output_tf.withWriter { w -> w << email_txt }

    if(skipped_poor_alignment.size() > 0){
        log.info "[rnaseq] WARNING - ${skipped_poor_alignment.size()} samples skipped due to poor alignment scores!"
    }

    log.info "[rnaseq] Pipeline Complete"

    if(!workflow.success){
        if( workflow.profile == 'test'){
        
            log.error "====================================================\n" +
                    "  WARNING! You are running with the profile 'test' only\n" +
                    "  pipeline config profile, which runs on the head node\n" +
                    "  and assumes all software is on the PATH.\n" +
                    "  This is probably why everything broke.\n" +
                    "  Please use `-profile test,curie` or `-profile test,singularity` to run on local.\n" +
                    "  Please use `-profile test,curie,cluster` or `-profile test,singularity,cluster` to run on your clusters.\n" +
                    "============================================================"
        }
    }
}

