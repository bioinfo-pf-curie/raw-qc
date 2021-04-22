#!/bin/bash

is_pe=$1
prefix=$2
if [ $is_pe == "0" ]; then
   reads_0=$3
   trims_0=$4
   
   zcat $reads_0|head -n 1000 > subset_${prefix}.R1.fastq
   gzip subset_${prefix}.R1.fastq

   zcat $trims_0|head -n 1000 > subset_${prefix}_trims.R1.fastq
   gzip subset_${prefix}_trims.R1.fastq
else
   reads_0=$3
   reads_1=$4
   trims_0=$5
   trims_1=$6

   zcat $reads_0|head -n 1000 > subset_${prefix}.R1.fastq
   gzip subset_${prefix}.R1.fastq

   zcat $reads_1|head -n 1000 > subset_${prefix}.R2.fastq
   gzip subset_${prefix}.R2.fastq

   zcat $trims_0|head -n 1000 > subset_${prefix}_trims.R1.fastq
   gzip subset_${prefix}_trims.R1.fastq

   zcat $trims_1|head -n 1000 > subset_${prefix}_trims.R2.fastq
   gzip subset_${prefix}_trims.R2.fastq

fi


