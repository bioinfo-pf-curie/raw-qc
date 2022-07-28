#!/usr/bin/env nextflow

/*
Copyright Institut Curie 2019-2022
This software is a computer program whose purpose is to analyze high-throughput sequencing data.
You can use, modify and/ or redistribute the software under the terms of license (see the LICENSE file for more details).
The software is distributed in the hope that it will be useful, but "AS IS" WITHOUT ANY WARRANTY OF ANY KIND.
Users are therefore encouraged to test the software's suitability as regards their requirements in conditions enabling the security of their systems and/or data.
The fact that you are presently reading this means that you have had knowledge of the license and that you accept its terms.
*/

/*
========================================================================================
                         DSL2 Template
========================================================================================
Analysis Pipeline DSL2 template.
https://patorjk.com/software/taag/
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl=2

// Initialize lintedParams and paramsWithUsage
NFTools.welcome(workflow, params)

// Use lintedParams as default params object
paramsWithUsage = NFTools.readParamsFromJsonSettings("${projectDir}/parameters.settings.json")
params.putAll(NFTools.lint(params, paramsWithUsage))

// Run name
customRunName = NFTools.checkRunName(workflow.runName, params.name)

// Custom functions/variables
mqcReport = []
include {checkAlignmentPercent} from './lib/functions'

/*
===================================
  SET UP CONFIGURATION VARIABLES
===================================
*/

// Genome-based variables

// Initialize variable from the genome.conf file
params.xengsortIndex = NFTools.getGenomeAttribute(params, 'xengsort', genome='pdx')

// Stage config files
multiqcConfigCh = Channel.fromPath(params.multiqcConfig)
outputDocsCh = Channel.fromPath("$projectDir/docs/output.md")
outputDocsImagesCh = file("$projectDir/docs/images/", checkIfExists: true)

/*
==========================
 VALIDATE INPUTS
==========================
*/

if ((params.reads && params.samplePlan) || (params.readPaths && params.samplePlan)){
  exit 1, "Input reads must be defined using either '--reads' or '--samplePlan' parameter. Please choose one way"
}

// Protocols
//if (params.picoV2 && params.rnaLig){
//  exit 1, "Options '--picoV2', 'rnaLig' cannot be used together. Please choose one option"
//}

// Not available for single-end
if (params.picoV2 && params.singleEnd){
  exit 1, "Options '--picoV2' cannot be used with single-end data !"
}

//if (params.rnaLig && params.singleEnd){
//  exit 1, "Options '--rnaLig' cannot be used with single-end data !"
//}

/*
==========================
 BUILD CHANNELS
==========================
*/

metadataCh           = params.metadata         ? Channel.fromPath(params.metadata, checkIfExists: true).collect()       : Channel.empty()
pdxIndexCh           = params.xengsortIndex    ? Channel.fromPath(params.xengsortIndex, checkIfExists: true).collect()  : Channel.empty()
fastqScreenGenomeCh  = Channel.of(params.genomes.fastqScreenGenomes)


/*
===========================
   SUMMARY
===========================
*/

summary = [
  'Pipeline Release': workflow.revision ?: null,
  'Run Name': customRunName,
  'Inputs' : params.samplePlan ?: params.reads ?: null,
  'Trimming' : params.trimTool,
  'Adapter 3prime' : params.adapter ?: null,
  'Clipping' : params.picoV2 ? 'picoV2' : params.rnaLig ? 'RNA Lig' : null,
  'Adapter 5prime' : params.adapter5 ?: params.smartSeqV4 ? "smartSeqV4" : null,
  'PolyA'  : params.polyA ?: null,
  'Trim N' : params.nTrim ?: null,
  'Min Len': params.minLen ?: null,
  'Min Qual': params.qualTrim ?: null,
  'Max Resources': "${params.maxMemory} memory, ${params.maxCpus} cpus, ${params.maxTime} time per job",
  'Container': workflow.containerEngine && workflow.container ? "${workflow.containerEngine} - ${workflow.container}" : null,
  'Profile' : workflow.profile,
  'OutDir' : params.outDir,
  'WorkDir': workflow.workDir,
  'CommandLine': workflow.commandLine
].findAll{ it.value != null }

workflowSummaryCh = NFTools.summarize(summary, workflow, params)

/*
==============================
  LOAD INPUT DATA
==============================
*/

// Load raw reads
rawReadsCh = NFTools.getInputData(params.samplePlan, params.reads, params.readPaths, params.singleEnd, params)

// Make samplePlan if not available
sPlanCh = NFTools.getSamplePlan(params.samplePlan, params.reads, params.readPaths, params.singleEnd)

/*
==================================
           INCLUDE
==================================
*/

// Workflows
include { fastqScreenFlow } from './nf-modules/local/subworkflow/fastqScreen'
include { trimgaloreFlow } from './nf-modules/local/subworkflow/trimgalore'
include { fastpFlow } from './nf-modules/local/subworkflow/fastp'

// Processes
include { getSoftwareVersions } from './nf-modules/common/process/utils/getSoftwareVersions'
include { outputDocumentation } from './nf-modules/common/process/utils/outputDocumentation'
include { generalMetrics } from './nf-modules/local/process/generalMetrics'
include { fastqc as fastqcRaw } from './nf-modules/common/process/fastqc/fastqc'
include { fastqc as fastqcTrim } from './nf-modules/common/process/fastqc/fastqc'
include { xengsort } from './nf-modules/common/process/xengsort/xengsort'
include { multiqc } from './nf-modules/local/process/multiqc'

/*
=====================================
            WORKFLOW
=====================================
*/

workflow {
  versionsCh = Channel.empty()

  main:

    // subroutines
    outputDocumentation(
      outputDocsCh,
      outputDocsImagesCh
    )

    // PROCESS: fastqc on raw data
    fastqcRaw(
      rawReadsCh
    )
    versionsCh = versionsCh.mix(fastqcRaw.out.versions)

    /*
    ======================================
    TRIMMING
    ======================================
    */

    // SUBWORKFLOW: Trimming

    trimReadsCh = rawReadsCh
    trimMqcCh = Channel.empty()
    if ( params.trimTool == 'trimgalore' && !params.skipTrimming){
      trimgaloreFlow(
        rawReadsCh
      )
      versionsCh = versionsCh.mix(trimgaloreFlow.out.versions)
      trimReadsCh = trimgaloreFlow.out.fastq
      trimMqcCh = trimgaloreFlow.out.mqc
    }else if ( params.trimTool == "fastp" && !params.skipTrimming){
      fastpFlow(
        rawReadsCh
      )
      versionsCh = versionsCh.mix(fastpFlow.out.versions)
      trimReadsCh = fastpFlow.out.fastq
      trimMqcCh = fastpFlow.out.mqc
    }
    
    /*
    ======================================
     WORK ON TRIMMED DATA IF ANY
    ======================================
    */

    // PROCESS: fastqc on trimmed reads
    fastqcTrim(
      trimReadsCh      
    )
    versionsCh = versionsCh.mix(fastqcTrim.out.versions)

    //SUBWORKFLOW: fastqScreen
    fastqScreenFlow(
      trimReadsCh,
      fastqScreenGenomeCh
    )
    versionsCh = versionsCh.mix(fastqScreenFlow.out.versions)
    
    // PROCESS: xengsort
    xengsort(
      trimReadsCh,
      pdxIndexCh.collect()
    )
    versionsCh = versionsCh.mix(xengsort.out.versions)


    //*******************************************
    // MULTIQC

    // Warnings that will be printed in the mqc report
    warnCh = Channel.empty()

    if (params.skipTrimming){
      inputMetricsCh = rawReadsCh.map{[it[0], it[1], []]}
    }else{
      inputMetricsCh = rawReadsCh.join(trimReadsCh)
    }

    generalMetrics(
      inputMetricsCh
    )

    if (!params.skipMultiqc){

      getSoftwareVersions(
        versionsCh.unique().collectFile()
      )

      multiqc(
        customRunName,
        sPlanCh.collect(),
        metadataCh.ifEmpty([]),
        multiqcConfigCh.ifEmpty([]),
        fastqcRaw.out.results.collect().ifEmpty([]),
	trimMqcCh.collect().ifEmpty([]),
	generalMetrics.out.csv.collect().ifEmpty([]),
	fastqcTrim.out.results.collect().ifEmpty([]),
        xengsort.out.logs.collect().ifEmpty([]),
        fastqScreenFlow.out.mqc.collect().ifEmpty([]),
	getSoftwareVersions.out.versionsYaml.collect().ifEmpty([]),
	workflowSummaryCh.collectFile(name: "workflow_summary_mqc.yaml"),
        warnCh.collect().ifEmpty([])
      )
      mqcReport = multiqc.out.report.toList()
    }
}

workflow.onComplete {
  NFTools.makeReports(workflow, params, summary, customRunName, mqcReport)
}
