/*
 * Compute statistics from trimmed fastq files
 */

process generalMetrics {
  tag "${meta.id}"
  label 'onlyLinux'
  label 'minCpu'
  label 'minMem'

  input:
  tuple val(meta), path(reads), path(trims)

  output:
  path '*stats.trim.csv', emit: csv

  when:
  task.ext.when == null || task.ext.when

  script:
  def prefix = task.ext.prefix ?: "${meta.id}"
  def args = task.ext.args ?: ''
  def inputs = meta.singleEnd ? "-i $reads" : "-i ${reads[0]} -I ${reads[1]}"
  def trims = trims ? meta.singleEnd ? "-t $trims" : "-t ${trims[0]} -T ${trims[1]}" : ""
  """
  general_metrics.sh \
    $inputs \
    $trims \
    -s ${meta.id} > ${prefix}_stats.trim.csv
  """
}