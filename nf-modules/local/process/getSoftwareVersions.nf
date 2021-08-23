process getSoftwareVersions {
  label 'python'
  label 'minCpu'
  label 'minMem'

  publishDir path:"${params.outDir}/softwareVersions", mode: 'copy'

  input:
  path 'v_trimgalore.txt'
  path 'v_fastp.txt'
  path 'v_atropos.txt'
  path 'v_fastqscreen.txt'
  path 'v_fastqc.txt'

  output:
  path 'software_versions_mqc.yaml', emit : softwareVersionsYamlCh

  script:
  """
  echo "${workflow.manifest.version}" &> v_pipeline.txt 2>&1 || true
  echo "${workflow.nextflow.version}" &> v_nextflow.txt 2>&1 || true
  scrape_software_versions.py &> software_versions_mqc.yaml
  """
}

