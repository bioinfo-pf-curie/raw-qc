/* 
 * define the data analysis workflow 
 */

/* 
 * include requires tasks 
 */
include { fastqc } from '../process/fastqc'

workflow qcFlow {
    // required inputs
    take:
      reads 
    // workflow implementation
    main:
      fastqc(reads)
    emit:
      fastqcResultsCh = fastqc.out.mqc   // channel: [ path *_fastqc.{zip,html} ]
      fastqcVersionCh = fastqc.out.version   // channel: [ path v_fastqc.txt ]
}
