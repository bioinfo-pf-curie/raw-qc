process fastqScreen {
  tag "${meta.id}"
  label 'fastqscreen'
  label 'medCpu'
  label 'medMem'

  input:
  path(genomes)
  tuple val(meta), path(reads)
  path(config)

  output:
  path("*_screen.txt"), emit: mqc
  path("*_screen.html"), emit: html
  path("versions.txt"), emit: versions

  when:
  task.ext.when == null || task.ext.when

  script:
  def args = task.ext.args ?: ''
  """
  fastq_screen ${args} --threads ${task.cpus} --conf ${config} ${reads}
  echo \$(fastq_screen --version | sed -e 's/FastQ Screen/FastqScreen/') > versions.txt
  """
}
