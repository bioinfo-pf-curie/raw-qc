#!/bin/bash

#################################################
##
## Compute triming statistics from fastq files
##
#################################################

while getopts ":i:I:t:T:s:n" OPT
do
    case $OPT in
	i) FASTQ=$OPTARG;;
	I) FASTQ_R2=$OPTARG;;
	t) FASTQ_TRIMMED=$OPTARG;;
	T) FASTQ_TRIMMED_R2=$OPTARG;;
	s) SAMPLE_NAME=$OPTARG;;
	\?)
	    echo "Invalid option: -$OPTARG" >&2
	    usage
	    exit 1
	    ;;
	:)
	    echo "Option -$OPTARG requires an argument." >&2
	    usage
	    exit 1
	    ;;
    esac
done

if [[ ! -e ${FASTQ} ]]; then
    echo -e "$FASTQ file not found"
    exit 1
fi

## Sample name
if [[ -z $SAMPLE_NAME ]]; then
    sample=$(basename $FASTQ | sed -e 's/.fastq.gz//')
else
    sample=$SAMPLE_NAME
fi

## Number of fragment - only need R1 reads
n_frag=$(zcat ${FASTQ} | wc -l)
n_frag=$(( $n_frag / 4 ))
n_reads=$n_frag

## Reads size distribution
zcat $FASTQ | awk 'NR%4 == 2 {lengths[length($0)]++} END {for (l in lengths) {print l, lengths[l]}}' > size_dist.txt
mean_length=$(awk '{n=n+$2; s=s+$1*$2}END{print s/n}' size_dist.txt)
total_base=$(awk '{s=s+$1*$2}END{print s}' size_dist.txt)
rm size_dist.txt

if [[ -e $FASTQ_R2 ]];then
    zcat $FASTQ_R2 | awk 'NR%4 == 2 {lengths[length($0)]++} END {for (l in lengths) {print l, lengths[l]}}' > size_dist_r2.txt
    mean_length_r2=$(awk '{n=n+$2; s=s+$1*$2}END{print s/n}' size_dist_r2.txt)
    total_base_r2=$(awk '{s=s+$1*$2}END{print s}' size_dist_r2.txt)
    mean_length=$(( ($mean_length + $mean_length_r2) /2 ))
    total_base=$(( $total_base + $total_base_r2 ))
    n_reads=$(( $n_reads * 2 ))
    rm size_dist_r2.txt
fi

## Trim stats
if [[ -e $FASTQ_TRIMMED ]]; then
    n_after_trim=$(zcat ${FASTQ_TRIMMED} | wc -l)
    n_after_trim=$(( $n_after_trim / 4 ))
    n_trim=$(awk -v l=${mean_length} '$1<l{s=s+$2}END{print s}' trim_size_dist.txt)
    p_trim=$(echo "${n_trim} ${n_frag}" | awk ' { printf "%.*f",2,$1*100/$2 } ')

    n_discarded=$(( $n_frag - $n_after_trim ))
    p_discarded=$(echo "${n_discarded} ${n_frag}" | awk ' { printf "%.*f",2,$1*100/$2 } ')

    zcat $FASTQ_TRIMMED | awk 'NR%4 == 2 {lengths[length($0)]++} END {for (l in lengths) {print l, lengths[l]}}' > trim_size_dist.txt
    trim_mean_length=$(awk '{n=n+$2; s=s+$1*$2}END{printf "%.*f",0,s/n}' trim_size_dist.txt)
    if [[ -e $FASTQ_TRIMMED_R2 ]]; then
	zcat $FASTQ_TRIMMED_R2 | awk 'NR%4 == 2 {lengths[length($0)]++} END {for (l in lengths) {print l, lengths[l]}}' > trim_size_dist_r2.txt
	trim_mean_length_r2=$(awk '{n=n+$2; s=s+$1*$2}END{printf "%.*f",0,s/n}' trim_size_dist_r2.txt)
	trim_mean_length=$(( ($trim_mean_length + $trim_mean_length_r2)/2 ))
	n_trim_r2=$(awk -v l=${mean_length_r2} '$1<l{s=s+$2}END{print s}' trim_size_dist_r2.txt)
	p_trim=$(echo "${n_trim} ${n_trim_r2} ${n_reads}" | awk ' { printf "%.*f",2,($1+$2)*100/$3 } ')
    fi
    rm trim_size_dist.txt
    rm trim_size_dist_r2.txt
else
    n_trim='NA'
    p_trim='NA'
    trim_mean_length='NA'
    n_discarded='NA'
    p_discarded='NA'
fi

echo -e "Sample_id,Number_of_frag,Mean_length,Total_base,Trimmed_Mean_length,Number_trimmed,Percent_trimmed,Number_discarded,Percent_discarded"
echo -e $sample,$n_frag,$mean_length,$total_base,$trim_mean_length,$n_trim,$p_trim,$n_discarded,$p_discarded
