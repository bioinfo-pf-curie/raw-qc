process fastp {
  label 'fastp'
  label 'medCpu'
  label 'medMem'

  publishDir "${params.outDir}/trimming", mode: 'copy'


  when:
  params.trimTool == "fastp" && !params.skipTrimming
  
  input:
  tuple val(name), path(reads)
  
  output:
  tuple val(name), path("*trimmed*fastq.gz"), emit: trimReads
  tuple val(name), path("*.{json,log}")     , emit: trimResults
  path("v_fastp.txt")                       , emit: version

  script:
  prefix = reads[0].toString() - ~/(_1)?(_2)?(_R1)?(_R2)?(.R1)?(.R2)?(_val_1)?(_val_2)?(\.fq)?(\.fastq)?(\.gz)?$/
  nextseqTrim = params.twoColour ? "--trim_poly_g" : "--disable_trim_poly_g"
  nTrim = params.nTrim ? "" : "--n_base_limit 0"
  picoOpts = ""
  polyAOpts = params.polyA ? "--trim_poly_x" : ""
  adapter = ""

  if (params.singleEnd) {
    // we don't usually have pico_version2 for single-end.
    if (params.picoV1) {
       picoOpts = "--trim_front1 3 --trim_tail1 3"
    } 

    if (params.adapter == 'truseq'){
      adapter ="--adapter_sequence ${params.truseqR1}"
    }else if (params.adapter == 'nextera'){
      adapter ="--adapter_sequence ${params.nexteraR1}"
    }else if (params.adapter == 'smallrna'){
      adapter ="--adapter_sequence ${params.smallrnaR1}"
    }
    """
    fastp --version &> v_fastp.txt 2>&1 || true
    fastp ${adapter} \
    --qualified_quality_phred ${params.qualTrim} \
    ${nextseqTrim} ${picoOpts} ${polyAOpts} \
    ${nTrim} \
    --length_required ${params.minLen} \
    -i ${reads} -o ${prefix}_trimmed_R1.fastq.gz \
    -j ${prefix}.fastp.json -h ${prefix}.fastp.html\
    --thread ${task.cpus} 2> ${prefix}_fasp.log
    """
  } else {
    if (params.picoV1) {
       picoOpts = "--trim_front1 3 --trim_tail2 3"
    }
    if (params.picoV2) {
       picoOpts = "--trim_front2 3 --trim_tail1 3"
    }

    if (params.rnaLig) {
       ligOpts = "--trim_front1 1 --trim_tail2 2 --trim_front2 1 --trim_tail1 2"
    }

    if (params.adapter == 'truseq'){
      adapter ="--adapter_sequence ${params.truseqR1} --adapter_sequence_r2 ${params.truseqR2}"
    }
    else if (params.adapter == 'nextera'){
      adapter ="--adapter_sequence ${params.nexteraR1} --adapter_sequence_r2 ${params.nexteraR2}"
    }
    """
    fastp --version &> v_fastp.txt 2>&1 || true
    fastp ${adapter} \
    --qualified_quality_phred ${params.qualTrim} \
    ${nextseqTrim} ${picoOpts} ${polyAOpts} ${ligOpts} \
    ${nTrim} \
    --length_required ${params.minLen} \
    -i ${reads[0]} -I ${reads[1]} -o ${prefix}_trimmed_R1.fastq.gz -O ${prefix}_trimmed_R2.fastq.gz \
    --detect_adapter_for_pe -j ${prefix}.fastp.json -h ${prefix}.fastp.html \
    --thread ${task.cpus} 2> ${prefix}_fasp.log
    """
  }
}
