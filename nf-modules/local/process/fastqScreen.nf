process fastqScreen {
  label 'fastqScreen'
  label 'medCpu'
  label 'medMem'
  publishDir "${params.outDir}/fastq_screen", mode: 'copy'

  when:
  !params.skipFastqScreen

  input:
  path fastqScreenGenomes
  tuple val(name), path(reads)
  path fastq_screen_config

  output:
  path("*_screen.txt")           , emit: fastqScreenTxt
  path("*_screen.html")          , emit: fastqScreenHtml
  path("*tagged_filter.fastq.gz"), emit: nohitsFastq
  path("v_fastqscreen.txt")      , emit: version

  script:
  """
  fastq_screen --force --subset 200000 --threads ${task.cpus} --conf ${fastq_screen_config} --nohits --aligner bowtie2 ${reads}
  fastq_screen --version &> v_fastqscreen.txt 2>&1 || true
  """
}


