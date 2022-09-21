/* 
 * Reads Trimming with TrimGalore
 */

include { trimGalore } from '../../common/process/trimGalore/trimGalore' 
include { cutadapt as trimAdapter5p } from '../../common/process/cutadapt/cutadapt'
include { cutadapt as trimPolyA } from '../../common/process/cutadapt/cutadapt'
include { trimmingSummary as trimmingSummary3p } from '../../local/process/trimmingSummary'
include { trimmingSummary as trimmingSummary5p } from '../../local/process/trimmingSummary'
include { trimmingSummary as trimmingSummaryPolyA } from '../../local/process/trimmingSummary'
//include { trimmingStats } from '../../local/process/trimmingStats'

workflow trimgaloreFlow {

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

  trimGalore(
    reads
  )
  chVersions = chVersions.mix(trimGalore.out.versions)
  chTrimReads = trimGalore.out.fastq

  trimmingSummary3p(
    trimGalore.out.logs
  )
  chTrimMqc = chTrimMqc.mix(trimmingSummary3p.out.mqc)
  chTrimLogs = chTrimLogs.mix(chTrimLogs)   

  /*
   ===========================
    Trim regular 5' adapters
   ===========================
  */

  if (params.adapter5 || params.smartSeqV4){
    trimAdapter5p(
      chTrimReads
    )
    chVersions = chVersions.mix(trimAdapter5p.out.versions)
    chTrimReads = trimAdapter5p.out.fastq

    trimmingSummary5p(
      trimAdapter5p.out.logs
    )
    chTrimMqc = chTrimMqc.mix(trimmingSummary5p.out.mqc)
    chTrimLogs = chTrimLogs.mix(trimAdapter5p.out.logs)
  }

  /*
   ===================
    Trim polyA tail
   ===================
  */

  if (params.polyA){
    trimPolyA(
      chTrimReads
    )
    chVersions = chVersions.mix(trimPolyA.out.versions)
    chTrimReads = trimPolyA.out.fastq
    
    trimmingSummaryPolyA(
      trimPolyA.out.logs
    )
    chTrimMqc = chTrimMqc.mix(trimmingSummaryPolyA.out.mqc)
    chTrimLogs = chTrimLogs.mix(trimPolyA.out.logs)
  }

  emit:
  fastq = chTrimReads
  logs = chTrimLogs
  mqc = chTrimMqc
  versions = chVersions
}

