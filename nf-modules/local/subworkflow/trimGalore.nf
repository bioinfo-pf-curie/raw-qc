/* 
 * Reads Trimming with TrimGalore
 */

include { trimGalore } from '../../common/process/trimGalore/trimGalore' 
include { trimGalore as trimGalorePolyA } from '../../common/process/trimGalore/trimGalore'

workflow trimGaloreFlow {

  take:
  reads

  main:

  // Trim adapaters sequence + quality
  trimGalore(
    reads
  )

  // Trim polyA tail
  trimGalorePolyA(
    trimGalore.out.fastq
  )

  emit:
  fastq = params.polyA ? trimGalorePolyA.out.fastq : trimGalore.out.fastq
  versions = trimGalore.out.versions
}

