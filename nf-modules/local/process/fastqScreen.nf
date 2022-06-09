process fastqScreen {
  label 'fastqScreen'
  label 'medCpu'
  label 'medMem'
  publishDir "${params.outDir}/fastq_screen", mode: 'copy'

  input:
  path fastqScreenGenomes
  tuple val(name), path(reads)
  path fastq_screen_config

  output:
  path("*_screen.txt")           , emit: fastqScreenTxt
  path("*_screen.html")          , emit: fastqScreenHtml
  path("*tagged_filter.fastq.gz"), emit: nohitsFastq
  path("versions.txt")      , emit: versions

  script:
  """
  fastq_screen --force --subset 200000 --threads ${task.cpus} --conf ${fastq_screen_config} --nohits --aligner bowtie2 ${reads}
  fastq_screen --version &> versions.txt 2>&1 || true
  """
}
