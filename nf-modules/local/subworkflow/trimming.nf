/* 
 * Reads Trimming with TrimGalore
 */

include { trimGalore } from '../../common/process/trimGalore/trimGalore' 
include { fastp } from '../../common/process/fastp/fastp'
include { cutadapt as cutLinker } from '../../common/process/cutadapt/cutadapt'
include { cutadapt as cutPolyA } from '../../common/process/cutadapt/cutadapt'

workflow trimmingFlow {

  take:
  reads

  main:
  chVersions = Channel.empty()
  chTrimReads = Channel.empty()
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
    chTrimReads = trimGalore.out.fastq
    chTrimLogs = trimGalore.out.logs
  }
  if (params.trimTool == 'fastp'){
    fastp(
      reads
    )
    chVersions = chVersions.mix(fastp.out.versions)
    chTrimReads = fastp.out.fastq
    chTrimLogs = fastp.out.logs
  }

 
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
    intermedReadsCh = cutLinker.out.fastq
  }else{
    intermedReadsCh = chTrimReads
  }


  /*
   ===================
    Trim polyA tail
   ===================
  */

  if (params.polyA){
    cutPolyA(
      intermedReadsCh
    )
    chVersions = chVersions.mix(cutPolyA.out.versions)
    trimReadsCh = cutPolyA.out.fastq
  }else{
    trimReadsCh = intermedReadsCh
  }

  emit:
  fastq = trimReadsCh
  logs = chTrimLogs
  versions = chVersions
}

