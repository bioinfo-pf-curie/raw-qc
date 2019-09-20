#!/bin/bash

is_pe=$1

totalreads=$(cat trimReport/*_Basic_Metrics.trim.txt|grep -v "Sample_name" |awk '{sums+= $3;} END {print sums}')

if [ $is_pe == "0" ]; then
   echo -e "Sample_name Biological_name Total_reads Sample_representation Mean_length Total_base Q20_R1 Trimmed_Mean_length Trimmed_reads Discarded_reads"|sed 's/ /\t/g' > mq_stats.tsv
   for file in trimReport/*_Basic_Metrics.trim.txt
   do
     cat ${file}|grep -v "Sample_name"|awk '{res=($3/"'$totalreads'")*100} END {printf  "%s\t%s\t%s\t%.2f%s\t%s\t%s\t%.2f%s\t%s\t%s%s\t%.2f%s\n",$1,$2,$3,res,"%",$4,$5,$6,"%",$7,$8,"%",$9,"%"}' >>  mq_stats.tsv
   done

else
   echo -e "Sample_name Biological_name Total_reads Sample_representation Mean_length Total_base Q20_R1 Q20_R2 Trimmed_Mean_length Trimmed_reads Discarded_reads"|sed 's/ /\t/g' > mq_stats.tsv
   for file in trimReport/*_Basic_Metrics.trim.txt
   do
     cat ${file}|grep -v "Sample_name"|awk '{res=($3/"'$totalreads'")*100} END {printf  "%s\t%s\t%s\t%.2f%s\t%s\t%s\t%.2f%s\t%.2f%s\t%s\t%.2f%s\t%.2f%s\n", $1,$2,$3,res,"%",$4,$5,$6,"%",$7,"%",$8,$9,"%",$10,"%"}' >> mq_stats.tsv
   done
fi
