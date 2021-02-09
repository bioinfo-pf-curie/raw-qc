#!/usr/bin/env python

import numpy as np
import re
import os
import json
from atropos.io.seqio import FastqReader
from optparse import OptionParser
import linecache

class Rawdata_Stat_Report(object):
    
    def get_options(self):
        usage = "usage: %prog [options] arg"
        parser = OptionParser(usage)
        parser.add_option("--r1", "--read1", dest="r1_file", default="", help="read data from raed1")
        parser.add_option("--r2", "--read2", dest="r2_file", default="", help="read data from read2")
        parser.add_option("--b", "--biological_name", dest="biological_name", default="", help="")
        parser.add_option("--o", "--output_file", dest="output_file", default="")
        ...
        (options, args) = parser.parse_args()
        ...
        ##print(options, args)
        args = []
        args = self.check_options(options.r1_file, options.r2_file, options.biological_name, options.output_file)
        return(args)
 
    def check_options(self,r1_file, r2_file, biological_name, output_file):
        """
          Check arguments in command lign.
        """
        if r1_file == "" and r2_file != "":
           print ('single end! nor paired end reads specified. Exiting.')
           exit(0)

        if r1_file != "" and r2_file != "":
                reads = [r1_file, r2_file]
        elif r1_file != "" and r2_file == "":
                reads = [r1_file]
        else:
                print ('No single end, nor paired end files specified. Exiting.')
                exit(0)

        if biological_name != "":
            biological_name = biological_name
        else:
            base = os.path.basename(reads[0])
            biological_name = os.path.splitext(base)[0].rsplit('.', 2)[0]

        if output_file != "":
            prefixname = output_file
        else:
            prefixname = biological_name 

        args = []
        args = (reads, biological_name, prefixname)
        return(args)

    def get_stat_raw(self, reads, biological_name):
        """
          Store read length for a seed of 1000 reads befor trimming.
        """
        try:
           base = os.path.basename(reads[0])
           sample = os.path.splitext(base)[0].rsplit('.', 2)[0]

           if len(reads) == 1:
              l_list = list()
              bases = list()
              raw_fastq = reads[0]
              with FastqReader(raw_fastq) as f:
                  for i, record in enumerate(f):
                      l = len(record)
                      l_list.append(l)

              self.total_reads = i 
              self.mean_length = np.mean(l_list)
              self.numBases = np.sum(l_list)


           if len(reads) == 2:
              l_list = list()
              bases = list()
              raw_R1_fastq = reads[0]
              raw_R2_fastq = reads[1]
              with FastqReader(raw_R1_fastq) as f:
                  for i, record in enumerate(f):
                      l = len(record)
                      l_list.append(l)
 
              self.total_reads_R1 = i
              self.mean_length_R1 = np.mean(l_list)
              self.numBases_R1 = np.sum(l_list)

              l_list = list()
              with FastqReader(raw_R2_fastq) as f:
                  for i, record in enumerate(f):
                      l = len(record)
                      l_list.append(l)
                 
              self.total_reads_R2 = i
              self.mean_length_R2 = np.mean(l_list)
              self.numBases_R2 = np.sum(l_list)
              
              self.total_reads = (self.total_reads_R1 + self.total_reads_R2)
              self.mean_length = (self.mean_length_R1 + self.mean_length_R2)/2
              self.numBases = (self.numBases_R1 + self.numBases_R2)
             
           stat_dict = dict(
              sample_name = sample,
              biological_name = biological_name,
              total_reads = str(self.total_reads),
              mean_length = str(self.mean_length), 
              numBases = str(self.numBases)
           )
           return stat_dict

        except ValueError: return False

    def write_stats_txt(self, len_reads, stats_dict, prefixname):
       """ Write json stats file.
       This file is read by MultiQC to summarize results of the trimming.
        Q20_R1', 'Q20_R2', 'Trimmed_Mean_length','trimmed_reads','discarded_reads'  will be "NA"
       """
       
       for key, value in stats_dict.items():
           if len_reads == 1:
             with open(prefixname + "_Basic_Metrics_rawdata.txt", 'w') as out:
               out.write('Sample_name'+'\t'+'Biological_name'+'\t'+'Total_reads'+'\t'+'Mean_length'+'\t'+'Total_base'+'\t'+'Q20_R1'+'\t'+'Trimmed_Mean_length'+'\t'+'Trimmed_reads'+'\t'+'Discarded_reads'+'\n')
               out.write(stats_dict.get('sample_name')+'\t'+stats_dict.get('biological_name')+'\t'+stats_dict.get('total_reads')+'\t'+stats_dict.get('mean_length')+'\t'+stats_dict.get('numBases')+'\t'+'NA'+'\t'+'NA'+'\t'+'NA'+'\t'+'NA'+'\n')
   
           if len_reads == 2:
             with open(prefixname + "_Basic_Metrics_rawdata.txt", 'w') as out:
              out.write('Sample_name'+'\t'+'Biological_name'+'\t'+'Total_reads'+'\t'+'Mean_length'+'\t'+'Total_base'+'\t'+'Q20_R1'+'\t'+'Q20_R2'+'\t'+'Trimmed_Mean_length'+'\t'+'Trimmed_reads'+'\t'+'Discarded_reads'+'\n')
              out.write(stats_dict.get('sample_name')+'\t'+stats_dict.get('biological_name')+'\t'+ stats_dict.get('total_reads')+'\t'+stats_dict.get('mean_length')+'\t'+stats_dict.get('numBases')+'\t'+'NA'+'\t'+ 'NA'+'\t'+'NA'+'\t'+'NA'+'\t'+'NA'+'\n')


if __name__ == '__main__':
    RSR = Rawdata_Stat_Report()
    args = RSR.get_options()
    reads = args[0]
    len_reads = len(reads)
    biological_name = args[1]
    prefixname = args[2]
    stat_dict = RSR.get_stat_raw(reads, biological_name)
    RSR.write_stats_txt(len_reads, stat_dict, prefixname)
