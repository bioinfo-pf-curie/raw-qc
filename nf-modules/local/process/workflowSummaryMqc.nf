
process workflowSummaryMqc {
  label 'python'
  label 'minCpu'
  label 'minMem'

  when:
  !params.skipMultiqc

  input:
  val(summary)

  output:
  path 'workflow_summary_mqc.yaml', emit: workflowSummaryYamlCh

  exec:
  def yaml_file = task.workDir.resolve('workflow_summary_mqc.yaml')
  yaml_file.text  = """
  id: 'summary'
  description: " - this information is collected when the pipeline is started."
  section_name: 'Workflow Summary'
  section_href: 'https://gitlab.curie.fr/data-analysis/rawqc'
  plot_type: 'html'
  data: |
        <dl class=\"dl-horizontal\">
  ${summary.collect { k,v -> "            <dt>$k</dt><dd><samp>${v ?: '<span style=\"color:#999999;\">N/A</a>'}</samp></dd>" }.join("\n")}
        </dl>
  """.stripIndent()
}
