#!/bin/bash

splan=$1
is_pe=$2

all_samples=$(awk -F, '{print $1}' $splan)
n_total=$(cat trimming/*stats.trim.csv | grep -v "Sample_id" |awk -F, '{s+= $2;} END {print s}')
n_header=0
for sample in $all_samples
do
    ##id
    sname=$(awk -F, -v sname=$sample '$1==sname{print $2}' $splan)

    ##trimming stats
    stats=$(awk -F, 'NR==2{print}' trimming/${sample}_stats.trim.csv)
    n_frag=$(awk -F, 'NR==2{print $2}' trimming/${sample}_stats.trim.csv)
    sfrac=$(echo "${n_frag} ${n_total}" | awk ' { printf "%.*f",2,$1*100/$2 } ')
    header="Sample_id,Number_of_frag,Mean_length,Total_base,Trimmed_Mean_length,Number_trimmed,Percent_trimmed,Number_discarded,Percent_discarded,Sample_name,Sample_representation"
    output="${stats},${sname},${sfrac}"

    ##PDX
    if [[ -e xengsort/${sample}_xengsort.log ]]; then
	n_host=$(awk -F"\t"  '$0!~"#" && $0!~"prefix"{print $2}' xengsort/${sample}_xengsort.log)
	p_host=$(echo "${n_host} ${n_frag}" | awk ' { printf "%.*f",2,$1*100/$2 } ')
	n_graft=$(awk -F"\t"  '$0!~"#" && $0!~"prefix"{print $3}' xengsort/${sample}_xengsort.log)
        p_graft=$(echo "${n_graft} ${n_frag}" | awk ' { printf "%.*f",2,$1*100/$2 } ')	
	header="$header,Number_pdx_host,Percent_pdx_host,Number_pdx_graft,Percent_pdx_graft"
	output="$output,${n_host},${p_host},${n_graft},${p_graft}"
    fi

    ##Q20 - require fastqc outputs
    q20_R1='NA'
    q20_R2='NA'

    if [[ $is_pe == "0" && -e fastqc/${sample}_fastqc.zip ]]; then
	q20_R1=$(unzip -p fastqc/${sample}_fastqc.zip ${sample}_fastqc/fastqc_data.txt | sed -n "/^>>Per sequence quality scores/,/>>END_MODULE/p" \
	    | awk -F"\t" -v qt=20 -v nfrag=${n_frag} '$1 ~ /^[0-9]+$/ && $1>=qt{s=s+$2}END{printf "%.*f",2,s*100/nfrag }')
	header="${header},Q20_R1"
	output="${output},${q20_R1}"

    elif [[ -e fastqc/${sample}_1_fastqc.zip && fastqc/${sample}_2_fastqc.zip ]]; then
	q20_R1=$(unzip -p fastqc/${sample}_1_fastqc.zip ${sample}_1_fastqc/fastqc_data.txt | sed -n "/^>>Per sequence quality scores/,/>>END_MODULE/p" \
	    | awk -F"\t" -v qt=20 -v nfrag=${n_frag} '$1 ~ /^[0-9]+$/ && $1>=qt{s=s+$2}END{printf "%.*f",2,s*100/nfrag }')
	q20_R2=$(unzip -p fastqc/${sample}_2_fastqc.zip ${sample}_2_fastqc/fastqc_data.txt | sed -n "/^>>Per sequence quality scores/,/>>END_MODULE/p" \
	    | awk -F"\t" -v qt=20 -v nfrag=${n_frag} '$1 ~ /^[0-9]+$/ && $1>=qt{s=s+$2}END{printf "%.*f",2,s*100/nfrag }')
	header="${header},Q20_R1,Q20_R2"
	output="${output},${q20_R1},${q20_R2}"
    fi

    if [ $n_header == 0 ]; then
	echo -e $header > mq.stats
	n_header=1
    fi
    echo -e $output >> mq.stats
done
