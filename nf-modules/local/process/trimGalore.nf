process trimGalore {
  label 'trimgalore'
  label 'medCpu'
  label 'medMem'
  publishDir "${params.outDir}/trimming", mode: 'copy'

  when:
  params.trimTool == "trimgalore" && !params.skipTrimming

  input:
  tuple val(name), path(reads)

  output:
  tuple val(name), path("*fastq.gz")           , emit: trimReads
  tuple val(name), path("*trimming_report.txt"), emit: trimResults
  path ("v_trimgalore.txt")                    , emit: version

  script:
  prefix = reads[0].toString() - ~/(_1)?(_2)?(_R1)?(_R2)?(.R1)?(.R2)?(_val_1)?(_val_2)?(\.fq)?(\.fastq)?(\.gz)?$/
  nTrim = params.nTrim ? "--trim-n" : ""
  qualTrim = params.twoColour ?  "--2colour ${params.qualTrim}" : "--quality ${params.qualTrim}"
  
  adapter = ""
  picoOpts = ""
  ligOpts = ""
  if (params.singleEnd) {
    if (params.picoV1) {
      picoOpts = "--clip_r1 3 --three_prime_clip_r2 3"
    }
    if (params.adapter == 'truseq'){
      adapter = "--adapter ${params.truseqR1}"
    }else if (params.adapter == 'nextera'){
      adapter = "--adapter ${params.nexteraR1}"
    }else if (params.adapter == 'smallrna'){
      adapter = "--adapter ${params.smallrnaR1}"
    }

    if (!params.polyA){
    """
    trim_galore --version &> v_trimgalore.txt 2>&1 || true
    trim_galore ${adapter} ${nTrim} ${qualTrim} \
                --length ${params.minLen} ${picoOpts} \
                --gzip $reads --basename ${prefix} --cores ${task.cpus}
    mv ${prefix}_trimmed.fq.gz ${prefix}_trimmed_R1.fastq.gz
    """
    }else{
    """
    trim_galore --version &> v_trimgalore.txt 2>&1 || true
    trim_galore ${adapter} ${nTrim} ${qualTrim} \
    		--length ${params.minLen} ${picoOpts} \
                --gzip $reads --basename ${prefix} --cores ${task.cpus}
    trim_galore -a "A{10}" ${qualTrim} --length ${params.minLen} \
                --gzip ${prefix}_trimmed.fq.gz --basename ${prefix}_polyA --cores ${task.cpus}
    rm ${prefix}_trimmed.fq.gz
    mv ${prefix}_polyA_trimmed_trimmed.fq.gz ${prefix}_trimmed_R1.fastq.gz
    mv ${prefix}_trimmed.fq.gz_trimming_report.txt ${prefix}_polyA_trimmingreport.txt
    """
    }
  }else {
    if (params.picoV1) {
       picoOpts = "--clip_r1 3 --three_prime_clip_r2 3"
    }
    if (params.picoV2) {
       picoOpts = "--clip_r2 3 --three_prime_clip_r1 3"
    }
    if (params.rnaLig) {
       ligOpts = "--clip_r1 1 --three_prime_clip_r2 2 --clip_r2 1 --three_prime_clip_r1 2"
    }

    if (params.adapter == 'truseq'){
      adapter ="--adapter ${params.truseqR1} --adapter2 ${params.truseqR2}"
    }else if (params.adapter == 'nextera'){
      adapter ="--adapter ${params.nexteraR1} --adapter2 ${params.nexteraR2}"
    }
    
    if (!params.polyA){
    """
    trim_galore --version &> v_trimgalore.txt 2>&1 || true
    trim_galore ${adapter} ${nTrim} ${qualTrim} \
                --length ${params.minLen} ${picoOpts} ${ligOpts} \
                --paired --gzip $reads --basename ${prefix} --cores ${task.cpus}
    mv ${prefix}_R1_val_1.fq.gz ${prefix}_trimmed_R1.fastq.gz
    mv ${prefix}_R2_val_2.fq.gz ${prefix}_trimmed_R2.fastq.gz
    """
    }else{
    """
    trim_galore --version &> v_trimgalore.txt 2>&1 || true
    trim_galore ${adapter} ${nTrim} ${qualTrim} \
                --length ${params.minLen} ${picoOpts} ${ligOpts} \
                --paired --gzip $reads --basename ${prefix} --cores ${task.cpus}

    trim_galore -a "A{10}" ${qualTrim} --length ${params.minLen} \
                 --paired --gzip ${prefix}_R1_val_1.fq.gz ${prefix}_R2_val_2.fq.gz --basename ${prefix}_polyA --cores ${task.cpus}

    mv ${prefix}_polyA_R1_val_1.fq.gz ${prefix}_trimmed_R1.fastq.gz
    mv ${prefix}_polyA_R2_val_2.fq.gz ${prefix}_trimmed_R2.fastq.gz
    mv ${prefix}_R1_val_1.fq.gz_trimming_report.txt ${prefix}_R1_polyA_trimmingreport.txt
    mv ${prefix}_R2_val_2.fq.gz_trimming_report.txt ${prefix}_R2_polyA_trimmingreport.txt
    rm ${prefix}_R1_val_1.fq.gz ${prefix}_R2_val_2.fq.gz
    """
    }
  }
   
}