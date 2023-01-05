/*
 * Rename a file
 */

process renameTrim {
  tag "${meta.id}"
  label 'onlylinux'
  label 'minCpu'
  label 'minMem'

  input:
  tuple val(meta), path(reads)

  output:
  tuple val(meta), path('*trimmed*fastq.gz'), emit: fastq

  when:
  task.ext.when == null || task.ext.when

  script:
  def prefix = task.ext.prefix ?: "${meta.id}"
  def args = task.ext.args ?: ''
  
  if (meta.singleEnd){
  """
  cp ${reads} ${prefix}_trimmed_R1.fastq.gz
  """
  }else{
  """
  cp ${reads[0]} ${prefix}_trimmed_${reads[0].simpleName.substring(reads[0].simpleName.lastIndexOf("_")+1)}.fastq.gz
  cp ${reads[1]} ${prefix}_trimmed_${reads[1].simpleName.substring(reads[1].simpleName.lastIndexOf("_")+1)}.fastq.gz
  """
  }
}