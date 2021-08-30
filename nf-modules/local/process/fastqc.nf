process fastqc {
  label 'fastqc'
  label 'lowCpu'
  label 'minMem'
  publishDir "${params.outDir}/fastqc", mode: 'copy'

  when:
  !params.skipFastqcRaw

  input:
  tuple val(name), path(reads)

  output:
  path("*_fastqc.{zip,html}"), emit: mqc 
  path("v_fastqc.txt")       , emit: version 

  script:
  """
  fastqc -q $reads -t ${task.cpus}
  fastqc --version &> v_fastqc.txt 2>&1 || true
  """
}

