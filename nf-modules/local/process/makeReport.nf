process makeReport {
    label 'python'
    label 'lowCpu'
    label 'extraMem'
    publishDir "${params.outDir}/makeReport", mode: 'copy'

    input:
    tuple val(name), path(reads), path(trims), path(reports)

    output:
    path '*_Basic_Metrics.trim.txt', emit: trimReport
    path "*_Adaptor_seq.trim.txt"  , emit: trimAdaptor

    script:
    prefix = reads[0].toString() - ~/(_1)?(_2)?(_R1)?(_R2)?(.R1)?(.R2)?(_val_1)?(_val_2)?(\.fq)?(\.fastq)?(\.gz)?$/
    isPE = params.singleEnd ? 0 : 1

    if (params.singleEnd) {
      if(params.trimTool == "fastp"){
      """
      create_subset_data.sh ${isPE} ${prefix} ${reads} ${trims}
      trimming_report.py --l ${prefix}_fasp.log --tr1 ${reports[0]} --r1 subset_${prefix}.R1.fastq.gz --t1 subset_${prefix}_trims.R1.fastq.gz --u ${params.trimTool} --b ${name} --o ${prefix}
      """
      } else {
      """
      create_subset_data.sh ${isPE} ${prefix} ${reads} ${trims}
      trimming_report.py --tr1 ${reports} --r1 subset_${prefix}.R1.fastq.gz --t1 subset_${prefix}_trims.R1.fastq.gz --u ${params.trimTool} --b ${name} --o ${prefix}
      """
      }
    } else {
      if(params.trimTool == "trimgalore"){
      """
      create_subset_data.sh ${isPE} ${prefix} ${reads} ${trims}
      trimming_report.py --tr1 ${reports[0]} --tr2 ${reports[1]} --r1 subset_${prefix}.R1.fastq.gz --r2 subset_${prefix}.R2.fastq.gz --t1 subset_${prefix}_trims.R1.fastq.gz --t2 subset_${prefix}_trims.R2.fastq.gz --u ${params.trimTool} --b ${name} --o ${prefix}
      """
      } else if (params.trimTool == "fastp"){
      """
      create_subset_data.sh ${isPE} ${prefix} ${reads} ${trims}
      trimming_report.py --l ${prefix}_fasp.log --tr1 ${reports[0]} --r1 subset_${prefix}.R1.fastq.gz --r2 subset_${prefix}.R2.fastq.gz --t1 subset_${prefix}_trims.R1.fastq.gz --t2 subset_${prefix}_trims.R2.fastq.gz --u ${params.trimTool} --b ${name} --o ${prefix}
      """
      } else {
      """
      create_subset_data.sh ${isPE} ${prefix} ${reads} ${trims}
      trimming_report.py --tr1 ${reports[0]} --r1 subset_${prefix}.R1.fastq.gz --r2 subset_${prefix}.R2.fastq.gz --t1 subset_${prefix}_trims.R1.fastq.gz --t2 subset_${prefix}_trims.R2.fastq.gz --u ${params.trimTool} --b ${name} --o ${prefix}
      """
      }
    }
  }