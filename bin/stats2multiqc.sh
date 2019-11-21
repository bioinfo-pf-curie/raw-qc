#!/bin/bash

is_pe=$1
isSkipTrim=$2


if [ $is_pe == "0" ]; then
   if [ $isSkipTrim == "0" ]; then
     totalreads=$(cat makeReport/*_Basic_Metrics_rawdata.txt|grep -v "Sample_name" |awk '{sums+= $3;} END {print sums}')
     echo -e "Sample_name Biological_name Total_reads Sample_representation Mean_length Total_base Q20_R1 Trimmed_Mean_length Trimmed_reads Discarded_reads"|sed 's/ /\t/g' > mq_stats_SE_rawdata.tsv
     for file in makeReport/*_Basic_Metrics_rawdata.txt
     do
       cat ${file}|grep -v "Sample_name"|awk '{res=($3/"'$totalreads'")*100} END {printf  "%s\t%s\t%s\t%.2f\t%s\t%s\t%s\t%s\t%s\t%s\n",$1,$2,$3,res,$4,$5,$6,$7,$8,$9}' >>  mq_stats_SE_rawdata.tsv
     done
   else
     totalreads=$(cat makeReport/*_Basic_Metrics.trim.txt|grep -v "Sample_name" |awk '{sums+= $3;} END {print sums}')
     echo -e "Sample_name Biological_name Total_reads Sample_representation Mean_length Total_base Q20_R1 Trimmed_Mean_length Trimmed_reads Discarded_reads"|sed 's/ /\t/g' > mq_stats_SE.tsv
     for file in makeReport/*_Basic_Metrics.trim.txt
     do
       cat ${file}|grep -v "Sample_name"|awk '{res=($3/"'$totalreads'")*100} END {printf  "%s\t%s\t%s\t%.2f\t%s\t%s\t%.2f\t%s\t%s\t%.2f\n",$1,$2,$3,res,$4,$5,$6,$7,$8,$9}' >>  mq_stats_SE.tsv
     done 
   fi

else
   if [ $isSkipTrim == "0" ]; then
     totalreads=$(cat makeReport/*_Basic_Metrics_rawdata.txt|grep -v "Sample_name" |awk '{sums+= $3;} END {print sums}')
     echo -e "Sample_name Biological_name Total_reads Sample_representation Mean_length Total_base Q20_R1 Q20_R2 Trimmed_Mean_length Trimmed_reads Discarded_reads"|sed 's/ /\t/g' >  mq_stats_PE_rawdata.tsv
     for file in makeReport/*_Basic_Metrics_rawdata.txt
     do
       cat ${file}|grep -v "Sample_name"|awk '{res=($3/"'$totalreads'")*100} END {printf  "%s\t%s\t%s\t%.2f\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $1,$2,$3,res,$4,$5,$6,$7,$8,$9,$10}' >>  mq_stats_PE_rawdata.tsv
     done 
   else 
     totalreads=$(cat makeReport/*_Basic_Metrics.trim.txt|grep -v "Sample_name" |awk '{sums+= $3;} END {print sums}')
     echo -e "Sample_name Biological_name Total_reads Sample_representation Mean_length Total_base Q20_R1 Q20_R2 Trimmed_Mean_length Trimmed_reads Discarded_reads"|sed 's/ /\t/g' >  mq_stats_PE.tsv
     for file in makeReport/*_Basic_Metrics.trim.txt
     do
       cat ${file}|grep -v "Sample_name"|awk '{res=($3/"'$totalreads'")*100} END {printf  "%s\t%s\t%s\t%.2f\t%s\t%s\t%.2f\t%.2f\t%s\t%.2f\t%.2f\n", $1,$2,$3,res,$4,$5,$6,$7,$8,$9,$10}' >> mq_stats_PE.tsv
     done
  fi
fi

