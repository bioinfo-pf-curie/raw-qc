/* 
 * Reads Trimming with Fastp
 */


include { fastp } from '../../common/process/fastp/fastp'
include { trimmingSummary as trimmingSummaryFastp } from '../../local/process/trimmingSummary'

workflow fastpFlow {

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

  fastp(
    reads
  )
  chVersions = chVersions.mix(fastp.out.versions)
  chTrimReads = fastp.out.fastq

  trimmingSummaryFastp(
    fastp.out.logs
  )

  emit:
  fastq = chTrimReads
  logs = fastp.out.logs
  mqc = trimmingSummary.out.mqc
  versions = chVersions
}

