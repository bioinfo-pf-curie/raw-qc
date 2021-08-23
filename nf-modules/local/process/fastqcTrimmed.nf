process fastqcTrimmed {
  label 'fastqc'
  label 'lowCpu'
  label 'minMem'
  publishDir "${params.outDir}/fastqc_trimmed", mode: 'copy'

  input:
  tuple val(name), path(reads)

  output:
  path ("*_fastqc.{zip,html}"), emit : fastqcAfterTrimResultsCh
  path ("v_fastqc.txt")       , emit : fastqcTrimmedVersionCh

  script:
  """
  fastqc -q $reads -t ${task.cpus}
  fastqc --version &> v_fastqc.txt 2>&1 || true
  """
}

