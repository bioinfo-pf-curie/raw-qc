process xengsort {

label 'medCpu'
label 'highMem'
label 'xengsort'


input :
tuple val(meta),path(reads)
path (index)

output :

tuple val(meta),path("*.fq"), emit: results
path("v_xengsort.txt") , emit: versions

script :
  def prefix = task.ext.prefix ?: "${meta.id}"
  if (meta.singleEnd){
    """
    echo \$(xengsort --version) > v_xengsort.txt
    xengsort classify -T ${task.cpus} --index ${index}  --fastq <(zcat ${reads}) --prefix ${prefix}.fq
    """
  }else{
    """
    echo \$(xengsort --version) > v_xengsort.txt
    xengsort classify -T ${task.cpus} --index ${index} --fastq <(zcat ${reads[0]})  --pairs <(zcat ${reads[1]}) --prefix ${prefix}
    """
  }
}
