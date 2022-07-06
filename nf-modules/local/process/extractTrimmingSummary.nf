/*
 * Build trimming report for MultiQC
 */

process extractTrimmingSummary {
  tag "${meta.id}"
  label 'python'
  label 'minCpu'
  label 'minMem'

  input:
  tuple val(meta), path(logs)

  output:
  path '*metrics.trim.tsv', emit: mqc

  when:
  task.ext.when == null || task.ext.when

  script:
  def prefix = task.ext.prefix ?: "${meta.id}"
  def args = task.ext.args ?: ''
  def inputsLogs = meta.singleEnd ? "-r ${logs}" : "-r ${logs[0]} -R ${logs[1]}"
  """
  trimming_report.py \
    ${inputsLogs} \
    ${args} \
    -n ${meta.id} -o ${prefix}
  """
}