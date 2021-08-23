/* 
 * FastqScreen 
 */

/* 
 * include requires tasks 
 */

include { fastqScreen } from '../process/fastqScreen' 
include { makeFastqScreenGenomeConfig } from '../process/makeFastqScreenGenomeConfig' 

/***********************
 * Header and conf
 */


workflow fastqScreenFlow {
    // required inputs
    take:
     fastqScreenGenomeCh
     trimReadsCh
    // workflow implementation
    main:
      makeFastqScreenGenomeConfig(
        fastqScreenGenomeCh
      )

      fastqScreen(
        Channel.fromList(params.genomes.fastqScreenGenomes.values().collect{file(it)}),
        trimReadsCh,
        makeFastqScreenGenomeConfig.out.fastqScreenConfigCh.collect()
      )

     emit:
       
       fastqScreenTxtCh     = fastqScreen.out.fastqScreenTxt  // channel: [ path("*_screen.txt") ]
       fastqScreenHtml      = fastqScreen.out.fastqScreenHtml // channel: [ path("*_screen.html") ]
       nohitsFastqCh        = fastqScreen.out.nohitsFastq     // channel: [ path("*tagged_filter.fastq.gz") ]
       fastqscreenVersionCh = fastqScreen.out.version         // channel: [ path("v_fastqscreen.txt") ]


}

