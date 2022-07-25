process makeFastqScreenGenomeConfig {
  label 'lowCpu'
  label 'minMem'
  label 'fastqscreen'

  input:
  val(fastqScreenGenome)

  output:
  path(outputFile), emit: fastqScreenConfigCh

  when:
  task.ext.when == null || task.ext.when

  script:
  outputFile = 'fastq_screen_databases.config'
  String result = ''
  for (Map.Entry entry: fastqScreenGenome.entrySet()) {
    result += """
    echo -e 'DATABASE\\t${entry.key}\\t${entry.value}' >> ${outputFile}"""
  }
  return result
}
