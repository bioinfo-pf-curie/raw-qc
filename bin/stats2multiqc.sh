#!/bin/bash

is_pe=$1

totalreads=$(cat trimReport/*_Basic_Metrics.trim.txt|grep -v "Sample_name" |awk '{sums+= $3;} END {print sums}')

if [ $is_pe == "0" ]; then
   echo -e "col1 col2 col3 col4 col5 col6 col7 col8 col9 col10"|sed 's/ /\t/g' > mq_stats_SE.tsv
   for file in trimReport/*_Basic_Metrics.trim.txt
   do
     cat ${file}|grep -v "Sample_name"|awk '{res=($3/"'$totalreads'")*100} END {printf  "%s\t%s\t%s\t%.2f\t%s\t%s\t%.2f\t%s\t%s\t%.2f\n",$1,$2,$3,res,$4,$5,$6,$7,$8,$9}' >>  mq_stats_SE.tsv
   done

else
   echo -e "col1 col2 col3 col4 col5 col6 col7 col8 col9 col10 col11"|sed 's/ /\t/g' > mq_stats_PE.tsv
   for file in trimReport/*_Basic_Metrics.trim.txt
   do
     echo ${file}
     cat ${file}|grep -v "Sample_name"|awk '{res=($3/"'$totalreads'")*100} END {printf  "%s\t%s\t%s\t%.2f\t%s\t%s\t%.2f\t%.2f\t%s\t%.2f\t%.2f\n", $1,$2,$3,res,$4,$5,$6,$7,$8,$9,$10}' >> mq_stats_PE.tsv
   done
fi
