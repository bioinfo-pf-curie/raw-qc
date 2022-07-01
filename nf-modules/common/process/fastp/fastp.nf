/*
 * Fastp trimming
 */

process fastp {
  tag "${meta.id}"
  label 'fastp'
  label 'medCpu'
  label 'medMem'

  input:
  tuple val(meta), file(reads)
  
  output:
  tuple val(meta), path("*trimmed*fastq.gz"), emit: fastq
  tuple val(meta), path("*.{json,log}"), emit: log
  path ("versions.txt"), emit: versions

  when:
  task.ext.when == null || task.ext.when

  script:
  def prefix = task.ext.prefix ?: "${meta.id}"
  def args = task.ext.args ?: ''
  def inputs = meta.singleEnd ? "-i ${reads} -o ${prefix}_trimmed.fastq.gz" : "--detect_adapter_for_pe -i ${reads[0]} -I ${reads[1]} -o ${prefix}_trimmed_R1.fastq.gz -O ${prefix}_trimmed_R2.fastq.gz"

  """
  fastp \
    ${args} \
    ${inputs} \
    -j ${prefix}.fastp.json -h ${prefix}.fastp.html \
    --thread ${task.cpus} 2> ${prefix}_fasp.log
  fastp --version 2>&1 > versions.txt
  """
}

