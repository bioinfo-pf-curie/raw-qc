/* 
 * Reads Trimming with TrimGalore
 */

include { trimGalore } from '../../common/process/trimGalore/trimGalore' 
include { cutadapt as cutLinker } from '../../common/process/cutadapt/cutadapt'
include { cutadapt as cutPolyA } from '../../common/process/cutadapt/cutadapt'
include { trimmingSummary as trimmingSummary3p } from '../../local/process/trimmingSummary'
include { trimmingSummary as trimmingSummary5p } from '../../local/process/trimmingSummary'
include { trimmingSummary as trimmingSummaryPolyA } from '../../local/process/trimmingSummary'
include { trimmingStats } from '../../local/process/trimmingStats'

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
    cutLinker(
      chTrimReads
    )
    chVersions = chVersions.mix(cutLinker.out.versions)
    chTrimReads = cutLinker.out.fastq

    trimmingSummary5p(
      cutLinker.out.logs
    )
    chTrimMqc = chTrimMqc.mix(trimmingSummary5p.out.mqc)
    chTrimLogs = chTrimLogs.mix(cutLinker.out.logs)
  }

  /*
   ===================
    Trim polyA tail
   ===================
  */

  if (params.polyA){
    cutPolyA(
      chTrimReads
    )
    chVersions = chVersions.mix(cutPolyA.out.versions)
    chTrimReads = cutPolyA.out.fastq
    
    trimmingSummaryPolyA(
      cutPolyA.out.logs
    )
    chTrimMqc = chTrimMqc.mix(trimmingSummaryPolyA.out.mqc)
    chTrimLogs = chTrimLogs.mix(cutPolyA.out.logs)
  }

  trimmingStats(
    reads.join(chTrimReads)
  )

  emit:
  fastq = chTrimReads
  logs = chTrimLogs
  mqc = chTrimMqc
  stats = trimmingStats.out.csv
  versions = chVersions
}

