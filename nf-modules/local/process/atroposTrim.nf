process atroposTrim {
  label 'atropos'
  label 'medCpu'
  label 'medMem'
  publishDir "${params.outDir}/trimming", mode: 'copy'

  
  when:
  params.trimTool == "atropos" && !params.skipTrimming && params.adapter != ""
  
  input:
  tuple val(name), path(reads)
  path sequences 

  output:
  path("*trimming_report*")                 , emit: trimResults
  tuple val(name), path("*trimmed*fastq.gz"), emit: trimReads
  tuple val(name), path("*.json")           , emit: reportResults
  path ("v_atropos.txt")                    , emit: version

  script:
  prefix = reads[0].toString() - ~/(_1)?(_2)?(_R1)?(_R2)?(.R1)?(.R2)?(_val_1)?(_val_2)?(\.fq)?(\.fastq)?(\.gz)?$/
  nTrim = params.nTrim ? "--trim-n" : ""
  nextseqTrim = params.twoColour ? "--nextseq-trim" : ""
  polyAOpts = params.polyA ? "-a A{10}" : ""

  if (params.singleEnd) {
  """
  if  [ "${params.adapter}" == "truseq" ]; then
     echo -e ">truseq_adapter_r1\n${params.truseqR1}" > ${prefix}_detect.0.fasta
  elif [ "${params.adapter}" == "nextera" ]; then
     echo -e ">nextera_adapter_r1\n${params.nexteraR1}" > ${prefix}_detect.0.fasta
  elif [ "${params.adapter}" == "smallrna" ]; then
     echo -e ">smallrna_adapter_r1\n${params.smallrnaR1}" > ${prefix}_detect.0.fasta
  fi
  atropos &> v_atropos.txt 2>&1 || true
  atropos trim -se ${reads} \
         --adapter file:${prefix}_detect.0.fasta \
         --times 3 --overlap 1 \
         --minimum-length ${params.minLen} --quality-cutoff ${params.qualTrim} \
         ${nTrim} ${nextseqTrim} ${polyAOpts} \
         --threads ${task.cpus} \
         -o ${prefix}_trimmed_R1.fastq.gz \
         --report-file ${prefix}_trimming_report \
         --report-formats txt json
  """
  } else {
  """
  if [ "${params.adapter}" == "truseq" ]; then
     echo -e ">truseq_adapter_r1\n${params.truseqR1}" > ${prefix}_detect.0.fasta
     echo -e ">truseq_adapter_r2\n${params.truseqR2}" > ${prefix}_detect.1.fasta
  elif [ "${params.adapter}" == "nextera" ]; then
     echo -e ">nextera_adapter_r1\n${params.nexteraR1}" > ${prefix}_detect.0.fasta
     echo -e ">nextera_adapter_r2\n${params.nexteraR2}" > ${prefix}_detect.1.fasta
  fi
  atropos &> v_atropos.txt 2>&1 || true
  atropos -pe1 ${reads[0]} -pe2 ${reads[1]} \
         --adapter file:${prefix}_detect.0.fasta -A file:${prefix}_detect.1.fasta \
         -o ${prefix}_trimmed_R1.fastq.gz -p ${prefix}_trimmed_R2.fastq.gz  \
         --times 3 --overlap 1 \
         --minimum-length ${params.minLen} --quality-cutoff ${params.qualTrim} \
         ${nTrim} ${nextseqTrim} ${polyAOpts} \
         --threads ${task.cpus} \
         --report-file ${prefix}_trimming_report \
         --report-formats txt json
  """
  }
}
