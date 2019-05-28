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
    nextflow run raw-qc --reads '*_R{1,2}.fastq.gz' -profile docker

    Mandatory arguments:
      --reads                       Path to input data (must be surrounded with quotes)
      -profile                      Configuration profile to use. Can use multiple (comma separated)
                                    Available: conda, docker, singularity, test and curie.

    Options:
      --singleEnd                   Specifies that the input is single end reads
      --trimtool		    Specifies adapter trimming tool ['trimgalore', 'atropos']. Default is 'trimgalore'

    Other options:
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
if (params.trimtool!= 'trimgalore' && params.trimtool != 'atropos'){
    exit 1, "Invalid trimming tool option: ${params.trimtool}. Valid options: 'trimgalore', 'atropos'"
} 

// Define regular variable so that they can be overwritten
if (params.trimtool == 'atropos'){
    trimming_opt = params.atropos_opts
}

if (params.trimtool == 'trimgalore'){
    trimming_opt = params.trimgalore_opts
}

// Stage config files
ch_multiqc_config = Channel.fromPath(params.multiqc_config)
ch_output_docs = Channel.fromPath("$baseDir/docs/output.md")
ch_adaptor_file_detect = Channel.fromPath("$baseDir/assets/sequencing_adapters.fa")
ch_adaptor_file_trim = Channel.fromPath("$baseDir/assets/sequencing_adapters.fa")


/*
 * CHANNELS
 */

if(params.readPaths){
  if(params.singleEnd){
    Channel
      .from(params.readPaths)
      .map { row -> [ row[0], [file(row[1][0])]] }
      .ifEmpty { exit 1, "params.readPaths was empty - no input files supplied" }
      .into { read_files_fastqc; read_files_trimgalore; read_files_atropos_detect; read_files_atropos_trim }
  } else {
     Channel
       .from(params.readPaths)
       .map { row -> [ row[0], [file(row[1][0]), file(row[1][1])]] }
       .ifEmpty { exit 1, "params.readPaths was empty - no input files supplied" }
       .into { read_files_fastqc; read_files_trimgalore; read_files_atropos_detect, read_files_atropos_detect }
  }
} else {
  Channel
    .fromFilePairs( params.reads, size: params.singleEnd ? 1 : 2 )
    .ifEmpty { exit 1, "Cannot find any reads matching: ${params.reads}\nNB: Path needs to be enclosed in quotes!\nIf this is single-end data, please specify --singleEnd on the command line." }
    .into { read_files_fastqc; read_files_trimgalore; read_files_atropos_detect; read_files_atropos_trim }
}


// Header log info
log.info """=======================================================

raw-qc v${workflow.manifest.version}"
======================================================="""
def summary = [:]
summary['Pipeline Name']  = 'rawqc'
summary['Pipeline Version'] = workflow.manifest.version
summary['Run Name']     = custom_runName ?: workflow.runName
summary['Reads']        = params.reads
summary['Data Type']    = params.singleEnd ? 'Single-End' : 'Paired-End'
summary['Trimming tool']= params.trimtool
if(params.trimtool == 'trimgalore'){
    summary['Trimming'] = params.trimgalore_opts
}else if (params.trimtool == 'atropos'){
    summary['Trimming'] = params.atropos_opts
}
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


def create_workflow_summary(summary) {
    def yaml_file = workDir.resolve('workflow_summary_mqc.yaml')
    yaml_file.text  = """
    id: 'raw-qc-summary'
    description: " - this information is collected when the pipeline is started."
    section_name: 'Raw-QC Workflow Summary'
    section_href: 'https://github.com/raw-qc'
    plot_type: 'html'
    data: |
        <dl class=\"dl-horizontal\">
${summary.collect { k,v -> "            <dt>$k</dt><dd><samp>${v ?: '<span style=\"color:#999999;\">N/A</a>'}</samp></dd>" }.join("\n")}
        </dl>
    """.stripIndent()

   return yaml_file
}


/*
 * Parse software version numbers
 
process get_software_versions {

    output:
    file 'software_versions_mqc.yaml' into software_versions_yaml

    script:
    // TODO : Get all tools to print their version number here
    """
    echo $workflow.manifest.version > v_pipeline.txt
    echo $workflow.nextflow.version > v_nextflow.txt
    multiqc --version > v_multiqc.txt
    scrape_software_versions.py > software_versions_mqc.yaml
    """
}

*/
/*
 * STEP 1 - FastQC
*/
process fastqc {
    tag "$name (raw)"
    //conda 'fastqc=0.11.8'
    publishDir "${params.outdir}/fastqc", mode: 'copy',
        saveAs: {filename -> filename.indexOf(".zip") > 0 ? "zips/$filename" : "$filename"}

    input:
    set val(name), file(reads) from read_files_fastqc

    output:
    file "*_fastqc.{zip,html}" into fastqc_results

    script:
    """
    fastqc -q $reads
    """
}



/*
 * STEP 2 - Reads Trimming
*/

process trim_galore {
  tag "$name" 

  //conda 'trim-galore=0.6.2'
  publishDir "${params.outdir}/trim", mode: 'copy',
    saveAs: {filename -> filename.indexOf("_fastqc") > 0 ? "FASTQC/$filename" : "$filename"}

  when:
  params.trimtool == "trimgalore"

  input:
  set val(name), file(reads) from read_files_trimgalore

  output:
  file "*fq.gz" into trim_reads_trimgalore
  file "*trimming_report.txt" into trim_results_trimgalore

  script:

  // Validate trimgalore_opts & syntax in configfile.
  if (trimming_opt.contains("0")) {
    exit 1, "The clipping value for reads should have a sensible value (> 0 and < read length). Please check 'trimgalore_opts' in config file!"
  }
  if (!trimming_opt.contains("--") && (!trimming_opt.isEmpty)) {
    exit 1, " Syntax error in config file!"
  }
 
  if (params.singleEnd) {
    """
    trim_galore --gzip $reads ${trimming_opt_bis}
    """
    }else {
    """
    trim_galore --paired --gzip $reads ${trimming_opt}
    """
  }
}


/*
 * STEP 2 - Trimming reads with Atropos! 
*/

process atroposDetect {
  tag "$name"

  when:
  params.trimtool =="atropos"

  input:
  set val(name), file(reads) from read_files_atropos_detect
  file sequences from ch_adaptor_file_detect

  script:
  if ( params.singleEnd ){
  """
  atropos detect --quiet --max_read 1000000 \
  	  	 -se ${reads} -F ${sequences} -o ${reads.baseName}_detect.atropos \
		 --no-default-contaminants --output-formats 'json' 'yaml'
  """
  }else{
  """
  atropos detect --quiet --max_read 1000000 \
                 -pe1 ${reads}[0] -pe2 ${reads}[1] -F ${sequences} \
		 -o ${reads[0].baseName}_detect.atropos \
                 --no-default-contaminants --output-formats 'json' 'yaml'
  """
  }
}


process atroposTrim {
  tag "$name"

  //conda 'atropos=1.1.16'
  publishDir "${params.outdir}/trim", mode: 'copy',
    saveAs: {filename -> filename.indexOf("_fastqc") > 0 ? "FASTQC/$filename" : "$filename"}
  
  when:
  params.trimtool == "atropos"
  
  input:
  set val(name), file(reads) from read_files_atropos_trim
  file sequences from ch_adaptor_file_trim

  output:
  file "*trimming_report.txt" into trim_results_atropos
  file "*_trimmed.fq.gz" into trim_reads_atropos

  script:
  if (params.singleEnd) {
  """
  atropos -a file:${sequences} -o ${reads.baseName}_trimmed.fq.gz -se ${reads} ${trimming_opt} \
  	  --info-file ${reads.baseName}.trimming_report.txt --threads 0
  """
  } else {
  """
  atropos trim -a file:${sequences} -o ${reads[0].baseName}_trimmed.fq.gz \
  	  -p ${reads[1].baseName}_trimmed.fq.gz -pe1 ${reads[0]} -pe2 ${reads[1]} \
	  --threads ${task.cpus} -report-file ${reads[0].baseName}.trimming_report.txt \
	  -report-formats 'json' 'yaml' --stats 'both'
  """
  }
}


/*
 * STEP 3 - FastQC after Trim!
*/

if(params.trimtool == "atropos"){
  trim_reads = trim_reads_atropos
}else{
  trim_reads = trim_reads_trimgalore
}

process fastqc_after_trim{
  tag "$name (trimmed reads)"

  publishDir "${params.outdir}/trim/FASTQC", mode: 'copy',
        	saveAs: {filename -> filename.indexOf(".zip") > 0 ? "zips/$filename" : "$filename"}

  input:
  file reads from trim_reads

  output:
  file "*_fastqc.{zip,html}" into trim_fastqc_results
  script:
  """
  fastqc -q $reads
  """
}


/*
 * STEP 4 - MultiQC
*/

if(params.trimtool == "atropos"){
  trim_reads = trim_reads_atropos
}else{
  trim_reads = trim_reads_trimgalore
}


process multiqc {
  //tag "${name.baseName -'_fastqc'}"
  publishDir "${params.outdir}/MultiQC", mode: 'copy'
  //conda 'multiqc'

  input:
  file multiqc_config from ch_multiqc_config
  file (fastqc:'fastqc/*') from fastqc_results.collect().ifEmpty([]) 
  file ('atropos/*') from trim_results_atropos.collect().ifEmpty([])
  file ('trimGalore/*') from trim_results_trimgalore.collect().ifEmpty([])
  file ('fastqc_trimmed/*') from trim_fastqc_results.collect().ifEmpty([])

  //file ('trim/*') from trimgalore_fastqc_reports.collect().ifEmpty([])
  // TODO nf-core: Add in log files from your new processes for MultiQC to find!
  //file ('software_versions/*') from software_versions_yaml
  //file workflow_summary from create_workflow_summary(summary)

  output:
  file "*multiqc_report.html" into multiqc_report
  file "*_data"

  script:
  //multiqc . -f $rtitle $rfilename --config $multiqc_config -m custom_content -m cutadapt -m fastqc
  //custom_runName="${name.baseName - '_fastqc'}"
  custom_runName=custom_runName ?: workflow.runName
  script:
  rtitle = custom_runName ? "--title \"$custom_runName\"" : ''
  rfilename = custom_runName ? "--filename " + custom_runName.replaceAll('\\W','_').replaceAll('_+','_') + "_multiqc_report" : ''

  // TODO nf-core: Specify which MultiQC modules to use with -m for a faster run time
  """
  multiqc . -f $rtitle $rfilename --config $multiqc_config -m custom_content -m cutadapt -m fastqc
  """
}


/*
 * Completion e-mail notification

workflow.onComplete {

    // Set up the e-mail variables
    def subject = "[nf-core/mypipeline] Successful: $workflow.runName"
    if(!workflow.success){
      subject = "[nf-core/mypipeline] FAILED: $workflow.runName"
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
    email_fields['summary']['Nextflow Version'] = workflow.nextflow.version
    email_fields['summary']['Nextflow Build'] = workflow.nextflow.build
    email_fields['summary']['Nextflow Compile Timestamp'] = workflow.nextflow.timestamp

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
    def smail_fields = [ email: params.email, subject: subject, email_txt: email_txt, email_html: email_html, baseDir: "$baseDir" ]
    def sf = new File("$baseDir/assets/sendmail_template.txt")
    def sendmail_template = engine.createTemplate(sf).make(smail_fields)
    def sendmail_html = sendmail_template.toString()

    // Send the HTML e-mail
    if (params.email) {
        try {
          if( params.plaintext_email ){ throw GroovyException('Send plaintext e-mail, not HTML') }
          // Try to send HTML e-mail using sendmail
          [ 'sendmail', '-t' ].execute() << sendmail_html
          log.info "[nf-core/mypipeline] Sent summary e-mail to $params.email (sendmail)"
        } catch (all) {
          // Catch failures and try with plaintext
          [ 'mail', '-s', subject, params.email ].execute() << email_txt
          log.info "[nf-core/mypipeline] Sent summary e-mail to $params.email (mail)"
        }
    }

    // Write summary e-mail HTML to a file
    def output_d = new File( "${params.outdir}/Documentation/" )
    if( !output_d.exists() ) {
      output_d.mkdirs()
    }
    def output_hf = new File( output_d, "pipeline_report.html" )
    output_hf.withWriter { w -> w << email_html }
    def output_tf = new File( output_d, "pipeline_report.txt" )
    output_tf.withWriter { w -> w << email_txt }

    log.info "[nf-core/mypipeline] Pipeline Complete"
}
*/
