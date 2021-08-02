/*
 *  MultiQC
 */

process multiqc {
  label 'multiqc'
  label 'medCpu'
  label 'medMem'
  publishDir "${params.outDir}/MultiQC", mode: 'copy'

  when:
  !params.skipMultiqc

  input:
  val customRunName
  path splan
  path metadata
  path multiqcConfig
  path (fastqc:'fastqc/*')
  path ('atropos/*')
  path ('trimGalore/*')
  path ('fastp/*')
  path (fastqc:'fastqc_trimmed/*')
  path ('fastq_screen/*')
  path ('makeReport/*')
  path ('makeReport/*')
  path ('software_versions/*')
  path ('workflow_summary/*')

  output:
  path splan
  path "*_report.html", emit: multiqcReport 
  path "*_data"
  path("v_multiqc.txt"), emit: multiqcVersion

  script:
  rtitle = custom_runName ? "--title \"$custom_runName\"" : ''
  rpathname = custom_runName ? "--filename " + custom_runName + "_rawqc_report" : '--filename rawqc_report'
  isPE = params.singleEnd ? 0 : 1
  isSkipTrim = params.skipTrimming ? 0 : 1
  metadataOpts = params.metadata ? "--metadata ${metadata}" : ""
  splanOpts = params.samplePlan ? "--splan ${params.samplePlan}" : ""

  """
  multiqc --version &> v_multiqc.txt 2>&1 || true
  mqc_header.py --name "Raw-QC" --version ${workflow.manifest.version} ${metadataOpts} ${splanOpts} > multiqc-config-header.yaml
  stats2multiqc.sh ${isPE} ${isSkipTrim}
  multiqc . -f $rtitle $rpathname -c $multiqcConfig -c multiqc-config-header.yaml -m custom_content -m cutadapt -m fastqc -m fastp -m fastq_screen
  """
}

