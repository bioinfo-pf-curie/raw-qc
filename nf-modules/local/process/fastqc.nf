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
  file( "*_fastqc.{zip,html}"), emit: mqc 
  file("v_fastqc.txt")        , emit: version 

  script:
  """
  fastqc -q $reads -t ${task.cpus}
  fastqc --version &> v_fastqc.txt 2>&1 || true
  """
}

