process xengsort {

  label 'medCpu'
  label 'highMem'
  label 'xengsort'

  input :
  tuple val(meta),path(reads)
  path (index)

  output :
  tuple val(meta),path("*graft*.fq.gz"), emit: fastqHuman
  tuple val(meta),path("*host*.fq.gz"), emit: fastqMouse
  path("versions.txt") , emit: versions

  script :
    def prefix = task.ext.prefix ?: "${meta.id}"
    if (meta.singleEnd){
      """
      echo \$(xengsort --version) > versions.txt
      xengsort classify -T ${task.cpus} --index ${index}  --fastq <(zcat ${reads}) --prefix ${prefix}
      gzip *.fq
      """
    }else{
      """
      echo \$(xengsort --version) > versions.txt
      xengsort classify -T ${task.cpus} --index ${index} --fastq <(zcat ${reads[0]})  --pairs <(zcat ${reads[1]}) --prefix ${prefix}
      gzip *.fq
      """
    }
}
