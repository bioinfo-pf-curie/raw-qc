process makeReport4RawData {
    label 'python'
    label 'medCpu'
    label 'medMem'
    publishDir "${params.outDir}/makeReport", mode: 'copy'

    input:
    tuple val(name), path(reads)

    output:
    path '*_Basic_Metrics_rawdata.txt', emit: trimReport

    script:
    prefix = reads[0].toString() - ~/(_1)?(_2)?(_R1)?(_R2)?(.R1)?(.R2)?(_val_1)?(_val_2)?(\.fq)?(\.fastq)?(\.gz)?$/
    if (params.singleEnd) {
    """
    rawdata_stat_report.py --r1 ${reads} --b ${name} --o ${prefix}
    """
    } else {
    """
    rawdata_stat_report.py --r1 ${reads[0]} --r2 ${reads[1]} --b ${name} --o ${prefix}
    """
   }
 }