/* 
 * Reads Trimming 
 */

/* 
 * include requires tasks 
 */

include { trimGalore } from '../process/trimGalore' 
include { atroposTrim } from '../process/atroposTrim' 
include { fastp } from '../process/fastp'

/***********************
 * Header and conf
 */


workflow readsTrimmingFlow {
    // required inputs
    take:
     readFilesCh
     adaptorFileCh
    // workflow implementation
    main:
      trimGalore(
        readFilesCh
      )

      atroposTrim(
        readFilesCh,
        adaptorFileCh.collect()
      )

      fastp(
        readFilesCh
      )

     emit:
      trimReadsTrimgaloreCh     = trimGalore.out.trimReads
      trimResultsTrimgaloreCh = trimGalore.out.trimResults
      trimgaloreVersionCh       = trimGalore.out.version

      trimReadsAtroposCh        = atroposTrim.out.trimReads
      trimResultsAtroposCh      = atroposTrim.out.trimResults
      reportResultsAtroposCh    = atroposTrim.out.reportResults
      atroposVersionCh          = atroposTrim.out.version

      trimReadsFastpCh          = fastp.out.trimReads
      reportResultsFastpCh      = fastp.out.trimResults
      fastpVersionCh            = fastp.out.version
}

