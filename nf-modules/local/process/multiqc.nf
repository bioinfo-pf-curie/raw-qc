/*
 *  MultiQC
 */

process multiqc {
  label 'multiqc'
  label 'medCpu'
  label 'medMem'

  input:
  val custom_runName
  path splan
  path metadata
  path multiqcConfig
  path ('fastqc/*')
  path ('trimming/*')
  path ('trimming/*')
  path ('fastqc_trimmed/*')
  path ('xengsort/*')
  path ('fastq_screen/*')
  path ('software_versions/*')
  path ('workflow_summary/*')
  path warnings

  output:
  path splan
  path "*_report.html", emit: report
  path "*_data"
  path("versions.txt"), emit: versions

  script:
  rtitle = custom_runName ? "--title \"$custom_runName\"" : ''
  rfilename = custom_runName ? "--filename " + custom_runName + "_rawqc_report" : '--filename rawqc_report'
  isPE = params.singleEnd ? 0 : 1
  metadataOpts = params.metadata ? "--metadata ${metadata}" : ""
  splanOpts = params.samplePlan ? "--splan ${params.samplePlan}" : ""

  """
  multiqc --version &> versions.txt 2>&1
  mqc_header.py --name "Raw-QC" --version ${workflow.manifest.version} ${metadataOpts} ${splanOpts} > multiqc-config-header.yaml
  stats2multiqc.sh ${splan} ${isPE}
  multiqc . -f $rtitle $rfilename -c $multiqcConfig -c multiqc-config-header.yaml -m custom_content -m cutadapt -m fastqc -m fastp -m fastq_screen
  """
}
