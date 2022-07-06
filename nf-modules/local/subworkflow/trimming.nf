/* 
 * Reads Trimming with TrimGalore
 */

include { trimGalore } from '../../common/process/trimGalore/trimGalore' 
include { fastp } from '../../common/process/fastp/fastp'
include { cutadapt as cutLinker } from '../../common/process/cutadapt/cutadapt'
include { cutadapt as cutPolyA } from '../../common/process/cutadapt/cutadapt'
include { extractTrimmingSummary as trimmingSummary3p } from '../../local/process/extractTrimmingSummary'
include { extractTrimmingSummary as trimmingSummary5p } from '../../local/process/extractTrimmingSummary'
include { extractTrimmingSummary as trimmingSummaryPolyA } from '../../local/process/extractTrimmingSummary'
include { trimmingStats } from '../../local/process/trimmingStats'

workflow trimmingFlow {

  take:
  reads

  main:
  chVersions = Channel.empty()
  chTrimReads = Channel.empty()
  chTrimMqc = Channel.empty()
  chTrimLogs = Channel.empty()

  /*
   =======================================================
    Trim regular 3' adapters sequence + quality + length
   =======================================================
  */

  if (params.trimTool == 'trimgalore'){
    trimGalore(
      reads
    )
    chVersions = chVersions.mix(trimGalore.out.versions)
    ch3pTrimReads = trimGalore.out.fastq
    ch3pTrimLogs = trimGalore.out.logs
  }

  if (params.trimTool == 'fastp'){
    fastp(
      reads
    )
    chVersions = chVersions.mix(fastp.out.versions)
    ch3pTrimReads = fastp.out.fastq
    ch3pTrimLogs = fastp.out.logs
  }

  trimmingSummary3p(
    ch3pTrimLogs
  )
  chTrimMqc = chTrimMqc.mix(trimmingSummary3p.out.mqc)
  chTrimLogs = chTrimLogs.mix(ch3pTrimLogs)   

  /*
   ===========================
    Trim regular 5' adapters
   ===========================
  */

  if (params.adapter5 || params.smartSeqV4){
    cutLinker(
      ch3pTrimReads
    )
    chVersions = chVersions.mix(cutLinker.out.versions)
    ch3p5pReadsCh = cutLinker.out.fastq

    trimmingSummary5p(
      cutLinker.out.logs
    )
    chTrimMqc = chTrimMqc.mix(trimmingSummary5p.out.mqc)
    chTrimLogs = chTrimLogs.mix(cutLinker.out.logs)

  }else{
    ch3p5pReadsCh = ch3pTrimReads
  }

  /*
   ===================
    Trim polyA tail
   ===================
  */
  if (params.polyA){
    cutPolyA(
      ch3p5pReadsCh
    )
    chVersions = chVersions.mix(cutPolyA.out.versions)
    chFinalTrimReads = cutPolyA.out.fastq
    
    trimmingSummaryPolyA(
      cutPolyA.out.logs
    )
    chTrimMqc = chTrimMqc.mix(trimmingSummaryPolyA.out.mqc)
    chTrimLogs = chTrimLogs.mix(cutPolyA.out.logs)

  }else{
    chFinalTrimReads = ch3p5pReadsCh
  }

  trimmingStats(
    reads.join(chFinalTrimReads)
  )

  emit:
  fastq = chFinalTrimReads
  logs = chTrimLogs
  mqc = chTrimMqc
  stats = trimmingStats.out.csv
  versions = chVersions
}

