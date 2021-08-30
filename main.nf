#!/usr/bin/env nextflow

/*
Copyright Institut Curie 2019-2021
This software is a computer program whose purpose is to analyze high-throughput sequencing data.
You can use, modify and/ or redistribute the software under the terms of license (see the LICENSE file for more details).
The software is distributed in the hope that it will be useful, but "AS IS" WITHOUT ANY WARRANTY OF ANY KIND. 
Users are therefore encouraged to test the software's suitability as regards their requirements in conditions enabling the security of their systems and/or data. 
The fact that you are presently reading this means that you have had knowledge of the license and that you accept its terms.
*/

/*
========================================================================================
                           Raw-QC
========================================================================================
 Raw QC Pipeline.
 #### Homepage / Documentation
 https://gitlab.curie.fr/data-analysis/raw-qc
----------------------------------------------------------------------------------------
*/
nextflow.enable.dsl=2

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
      --polyA [bool]                Sets trimming setting for 3'-seq analysis with polyA tail detection

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
if (params.trimTool != 'trimgalore' && params.trimTool != 'atropos' && params.trimTool != 'fastp' ){
  exit 1, "Invalid trimming tool option: ${params.trimTool}. Valid options: 'trimgalore', 'atropos', 'fastp'"
} 

if (params.adapter != 'truseq' && params.adapter != 'nextera' && params.adapter != 'smallrna' && params.adapter!= 'auto' ){
  exit 1, "Invalid adaptator seq tool option: ${params.adapter}. Valid options: 'truseq', 'nextera', 'smallrna', 'auto'"
}

if (params.adapter == 'auto' && params.trimTool == 'atropos') {
  exit 1, "Cannot use Atropos without specifying --adapter sequence."
}

if (params.adapter == 'smallrna' && !params.singleEnd){
  exit 1, "smallRNA requires singleEnd data."
}

/*
if (params.nTrim && params.trimTool == 'fastp') {
  log.warn "[raw-qc] The 'nTrim' option is not availabe for the 'fastp' trimmer. Option is ignored."
}
*/

if (params.picoV1 && params.picoV2 && params.rnaLig){
  exit 1, "Invalid SMARTer kit option at the same time for pico1 && picoV2 && rnaLig"
}

if (params.picoV1 && params.picoV2 && params.trimTool == 'atropos'){
  exit 1, "Cannot use Atropos for pico preset"
}

if (params.singleEnd && params.picoV2){
  exit 1, "Cannot use --picoV2 for single end."
}

// Stage config files
multiqcConfigCh = Channel.fromPath(params.multiqcConfig)
outputDocsCh = Channel.fromPath("$baseDir/docs/output.md")
outputDocsImagesCh = file("$baseDir/docs/images/", checkIfExists: true)
adaptorFileDetectCh = Channel.fromPath("$baseDir/assets/sequencing_adapters.fa")
adaptorFileDefaultCh = Channel.fromPath("$baseDir/assets/sequencing_adapters.fa")

// FastqScreen
Channel
  .from(params.genomes.fastqScreenGenomes)
  .set{ fastqScreenGenomeCh }

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
      .set { readFilesCh}
  }else{
    Channel
      .from(file("${params.samplePlan}"))
      .splitCsv(header: false)
      .map{ row -> [ row[1], [file(row[2]), file(row[3])]] }
      .set { readFilesCh}
   }
   params.reads=false
}
else if(params.readPaths){
  if(params.singleEnd){
    Channel
      .from(params.readPaths)
      .map { row -> [ row[0], [file(row[1][0])]] }
      .ifEmpty { exit 1, "params.readPaths was empty - no input files supplied" }
      .set { readFilesCh }
  } else {
    Channel
      .from(params.readPaths)
      .map { row -> [ row[0], [file(row[1][0]), file(row[1][1])]] }
      .ifEmpty { exit 1, "params.readPaths was empty - no input files supplied" }
      .set { readFilesCh }
  }
} else {
    Channel
      .fromFilePairs( params.reads, size: params.singleEnd ? 1 : 2 )
      .ifEmpty { exit 1, "Cannot find any reads matching: ${params.reads}\nNB: Path needs to be enclosed in quotes!\nNB: Path requires at least one * wildcard!\nIf this is single-end data, please specify --singleEnd on the command line\
." }
      .set { readFilesCh }
}

/*
 * Make sample plan if not available
 */

if (params.samplePlan){
  splanCh = Channel.fromPath(params.samplePlan)
}else if(params.readPaths){
  if (params.singleEnd){
    Channel
      .from(params.readPaths)
      .collectFile() {
        item -> ["sample_plan.csv", item[0] + ',' + item[0] + ',' + item[1][0] + '\n']
      }
      .set{ splanCh }
  }else{
    Channel
      .from(params.readPaths)
      .collectFile() {
        item -> ["sample_plan.csv", item[0] + ',' + item[0] + ',' + item[1][0] + ',' + item[1][1] + '\n']
      }
      .set{ splanCh }
   }
}else{
  if (params.singleEnd){
    Channel
      .fromFilePairs( params.reads, size: 1 )
      .collectFile() {
        item -> ["sample_plan.csv", item[0] + ',' + item[0] + ',' + item[1][0] + '\n']
      }
      .set { splanCh }
  }else{
    Channel
      .fromFilePairs( params.reads, size: 2 )
      .collectFile() {
        item -> ["sample_plan.csv", item[0] + ',' + item[0] + ',' + item[1][0] + ',' + item[1][1] + '\n']
      }
      .set { splanCh }
   }
}

if ( params.metadata ){
   Channel
     .fromPath( params.metadata )
     .ifEmpty { exit 1, "Metadata file not found: ${params.metadata}" }
     .set { metadataCh }
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
summary['Trimming tool']= params.trimTool
summary['Adapter']= params.adapter
summary['Min quality']= params.qualTrim
summary['Min len']= params.minLen
summary['N trim']= params.nTrim ? 'True' : 'False'
summary['Two colour']= params.twoColour ? 'True' : 'False'
if (params.picoV1) {
   summary['PicoV1'] = 'True'
}
if(params.picoV2) {
   summary['PicoV2'] = 'True'
}
if (!params.picoV1 && !params.picoV2) {
   summary['Pico'] = 'False'
}
summary['RNA Lig']=params.rnaLig ? 'True' : 'False'
summary['PolyA']= params.polyA ? 'True' : 'False'
summary['Max Memory']   = params.maxMemory
summary['Max CPUs']     = params.maxCpus
summary['Max Time']     = params.maxTime
summary['Container Engine'] = workflow.containerEngine
summary['Current home']   = "$HOME"
summary['Current user']   = "$USER"
summary['Current path']   = "$PWD"
summary['Working dir']    = workflow.workDir
summary['Output dir']     = params.outDir
summary['Config Profile'] = workflow.profile

log.info summary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "========================================="

// Workflows
include { qcFlow } from './nf-modules/local/subworkflow/qc'
include { readsTrimmingFlow } from './nf-modules/local/subworkflow/readstrimming'
include { makeReportsFlow } from './nf-modules/local/subworkflow/makereport'
include { fastqScreenFlow } from './nf-modules/local/subworkflow/screens'
// Processes
include { getSoftwareVersions } from './nf-modules/local/process/getSoftwareVersions'
include { workflowSummaryMqc } from './nf-modules/local/process/workflowSummaryMqc'
include { multiqc } from './nf-modules/local/process/multiqc'
include { outputDocumentation } from './nf-modules/local/process/outputDocumentation'
include { fastqcTrimmed } from './nf-modules/local/process/fastqcTrimmed'

workflow {
    main:

      // subroutines
      outputDocumentation(
        outputDocsCh,
        outputDocsImagesCh
      )

      // QC : check factqc
      qcFlow(
        readFilesCh
      )

      /*
      ================================================================================
                                      Reads Trimming
      ================================================================================
*/
      trimReadsCh   = Channel.empty()
      trimReportsCh = Channel.empty()
      if (!params.skipTrimming){
        // Reads Trimming 
        readsTrimmingFlow(
          readFilesCh,
          adaptorFileDefaultCh
        )

        if(params.trimTool == "atropos"){
          trimReadsCh = readsTrimmingFlow.out.trimReadsAtroposCh
          trimReportsCh = readsTrimmingFlow.out.reportResultsAtroposCh
        }else if (params.trimTool == "trimgalore"){
          trimReadsCh = readsTrimmingFlow.out.trimReadsTrimgaloreCh
          trimReportsCh = readsTrimmingFlow.out.trimResultsTrimgaloreCh
        }else if (params.trimTool == "fastp"){
          trimReadsCh = readsTrimmingFlow.out.trimReadsFastpCh
          trimReportsCh = readsTrimmingFlow.out.reportResultsFastpCh
        }
      }


      /*
      ================================================================================
                                        Make Reports
      ================================================================================
      */
      
      makeReportsFlow(
        readFilesCh,
        trimReadsCh,
        trimReportsCh
      )
    

      /*
      ================================================================================
                                    QC on trim data [FastQC]
      ================================================================================
      */

      fastqcTrimmed(
        trimReadsCh
      )
      if (params.skipFastqcTrim || params.skipTrimming){
        fastqcTrimmed.out.fastqcAfterTrimResultsCh = Channel.empty()
      }
      /*
      ================================================================================
                                          FastqScreen
      ================================================================================
      */
      fastqScreenFlow(
        fastqScreenGenomeCh,
        trimReadsCh
      )

      /*
      ================================================================================
                                           MultiQC
      ================================================================================
      */
      getSoftwareVersions(
        readsTrimmingFlow.out.trimgaloreVersionCh.first().ifEmpty([]),
        readsTrimmingFlow.out.fastpVersionCh.first().ifEmpty([]),
        readsTrimmingFlow.out.atroposVersionCh.first().ifEmpty([]),
        fastqScreenFlow.out.fastqscreenVersionCh.first().ifEmpty([]),
        qcFlow.out.fastqcVersionCh.mix(fastqcTrimmed.out.fastqcTrimmedVersionCh).first().ifEmpty([])
      )

      workflowSummaryMqc(
        summary
      )

      multiqc(
        custom_runName,
        splanCh.collect(),
        metadataCh.ifEmpty([]),
        multiqcConfigCh, 
        qcFlow.out.fastqcResultsCh.collect().ifEmpty([]),
        readsTrimmingFlow.out.trimResultsAtroposCh.collect().ifEmpty([]),
        readsTrimmingFlow.out.trimResultsTrimgaloreCh.map{items->items[1]}.collect().ifEmpty([]),
        readsTrimmingFlow.out.reportResultsFastpCh.map{items->items[1]}.collect().ifEmpty([]),
        fastqcTrimmed.out.fastqcAfterTrimResultsCh.collect().ifEmpty([]),
        fastqScreenFlow.out.fastqScreenTxtCh.collect().ifEmpty([]),
        trimReportsCh.collect().ifEmpty([]),
        makeReportsFlow.out.trimAdaptorCh.collect().ifEmpty([]),
        getSoftwareVersions.out.softwareVersionsYamlCh.collect(),
        workflowSummaryMqc.out.workflowSummaryYamlCh.collect()
      )
}

/* Creates a file at the end of workflow execution */
workflow.onComplete {
  /*pipeline_report.html*/
  def report_fields = [:]
  report_fields['version'] = workflow.manifest.version
  report_fields['runName'] = customRunName ?: workflow.runName
  report_fields['success'] = workflow.success
  report_fields['dateComplete'] = workflow.complete
  report_fields['duration'] = workflow.duration
  report_fields['exitStatus'] = workflow.exitStatus
  report_fields['errorMessage'] = (workflow.errorMessage ?: 'None')
  report_fields['errorReport'] = (workflow.errorReport ?: 'None')
  report_fields['commandLine'] = workflow.commandLine
  report_fields['projectDir'] = workflow.projectDir
  report_fields['summary'] = summary
  report_fields['summary']['Date Started'] = workflow.start
  report_fields['summary']['Date Completed'] = workflow.complete
  report_fields['summary']['Pipeline script file path'] = workflow.scriptFile
  report_fields['summary']['Pipeline script hash ID'] = workflow.scriptId
  if(workflow.repository) report_fields['summary']['Pipeline repository Git URL'] = workflow.repository
  if(workflow.commitId) report_fields['summary']['Pipeline repository Git Commit'] = workflow.commitId
  if(workflow.revision) report_fields['summary']['Pipeline Git branch/tag'] = workflow.revision

  // Render the TXT template
  def engine = new groovy.text.GStringTemplateEngine()
  def tf = new File("$baseDir/assets/onCompleteTemplate.txt")
  def txt_template = engine.createTemplate(tf).make(report_fields)
  def report_txt = txt_template.toString()

  // Render the HTML template
  def hf = new File("$baseDir/assets/onCompleteTemplate.html")
  def html_template = engine.createTemplate(hf).make(report_fields)
  def report_html = html_template.toString()
  // Write summary e-mail HTML to a file
  def output_d = new File( "${params.summaryDir}/" )
  if( !output_d.exists() ) {
    output_d.mkdirs()
  }
  def output_hf = new File( output_d, "pipelineReport.html" )
  output_hf.withWriter { w -> w << report_html }
  def output_tf = new File( output_d, "pipelineReport.txt" )
  output_tf.withWriter { w -> w << report_txt }
  /*oncomplete file*/
  File woc = new File("${params.outDir}/workflowOnComplete.txt")
  Map endSummary = [:]
  endSummary['Completed on'] = workflow.complete
  endSummary['Duration']     = workflow.duration
  endSummary['Success']      = workflow.success
  endSummary['exit status']  = workflow.exitStatus
  endSummary['Error report'] = workflow.errorReport ?: '-'
  String endWfSummary = endSummary.collect { k,v -> "${k.padRight(30, '.')}: $v" }.join("\n")
  println endWfSummary
  String execInfo = "Execution summary\n${endWfSummary}\n"
  woc.write(execInfo)
 
  /*final logs*/
  if(workflow.success){
    log.info "[rawqc] Pipeline Complete"
  }else{
    log.info "[rawqc] FAILED: $workflow.runName"
  } 
}


