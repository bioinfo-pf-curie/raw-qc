/* 
 * FastqScreen 
 */

include { fastqScreen } from '../../common/process/fastqScreen/fastqScreen' 
include { makeFastqScreenGenomeConfig } from '../../common/process/fastqScreen/makeFastqScreenGenomeConfig' 

workflow fastqScreenFlow {

  take:
  reads
  genome

  main:
  chVersions = Channel.empty()
  makeFastqScreenGenomeConfig(
    genome
  )

  fastqScreen(
    Channel.fromList(params.genomes.fastqScreenGenomes.values().collect{file(it)}),
    reads,
    makeFastqScreenGenomeConfig.out.fastqScreenConfigCh.collect()
  )
  chVersions = chVersions.mix(fastqScreen.out.versions)

  emit:
  html = fastqScreen.out.html
  mqc = fastqScreen.out.mqc
  versions = chVersions
}

