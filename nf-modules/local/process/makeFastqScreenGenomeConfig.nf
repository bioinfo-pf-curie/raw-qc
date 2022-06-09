process makeFastqScreenGenomeConfig {
  label 'lowCpu'
  label 'minMem'
  publishDir "${params.outDir}/fastq_screen", mode: 'copy'

  input:
  val(fastqScreenGenome)

  output:
  path(outputFile), emit: fastqScreenConfigCh

  script:
    outputFile = 'fastq_screen_databases.config'

    String result = ''
    for (Map.Entry entry: fastqScreenGenome.entrySet()) {
      result += """
      echo -e 'DATABASE\\t${entry.key}\\t${entry.value}' >> ${outputFile}"""
    }
    return result
}
