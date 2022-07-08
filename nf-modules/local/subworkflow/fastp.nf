/* 
 * Reads Trimming with Fastp
 */


include { fastp } from '../../common/process/fastp/fastp'
include { trimmingSummary } from '../../local/process/trimmingSummary'
include { trimmingStats } from '../../local/process/trimmingStats'

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

  trimmingSummary(
    fastp.out.logs
  )

  trimmingStats(
    reads.join(chTrimReads)
  )

  emit:
  fastq = chTrimReads
  logs = fastp.out.logs
  mqc = trimmingSummary.out.mqc
  stats = trimmingStats.out.csv
  versions = chVersions
}

