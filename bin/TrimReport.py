#!/usr/bin/env python

import numpy as np
import re
import os
import json
from collections import defaultdict
from atropos.io.seqio import FastqReader
from optparse import OptionParser

class TrimReport(object):
    
    def get_options(self):
        usage = "usage: %prog [options] arg"
        parser = OptionParser(usage)
        parser.add_option("--r1", "--read1", dest="r1_file", default="", help="read data from raed1")
        parser.add_option("--r2", "--read2", dest="r2_file", default="", help="read data from read2")
        parser.add_option("--t1", "--trim1", dest="trim1_file", default="", help="read trim data for read1")
        parser.add_option("--t2", "--trim2", dest="trim2_file", default="", help="read trim data for read2")
        parser.add_option("--a", "--adaptor", dest="adaptor_file", default="", help="read adaptor sequence from detect adaptor of tools")
        parser.add_option("--o", "--output_file", dest="output_file", default="")
        ...
        (options, args) = parser.parse_args()
        ...
#        print(options, args)
        args = []
        args = self.check_options(options.r1_file,options.r2_file, options.trim1_file, options.trim2_file, options.adaptor_file, options.output_file)
        return(args)
 
    def check_options(self, r1_file, r2_file, trim1_file, trim2_file, adaptor_file, output_file):
        """
          Check arguments in command lign.
        """

        if r1_file == "" and r2_file != "":
           print ('single end! nor paired end reads specified. Exiting.')
           exit(0)
        
        if trim1_file=="" and trim2_file !="":
           print ('single end! nor paired end trim specified. Exiting.')
           exit(0)

        if r1_file != "" and r2_file != "":
                reads = [r1_file, r2_file]
                print ('Read 1 and Read 2')
        elif r1_file != "" and r2_file == "":
                reads = [r1_file]
                print ('Single end')
        else:
                print ('No single end, nor paired end files specified. Exiting.')
                exit(0)

        if trim1_file != "" and trim2_file !="":
               trims = [trim1_file, trim2_file]
        elif trim1_file != "" and trim2_file =="":
               trims = [trim1_file]
        else:
               print ('No single trim, nor paired trim files specified. Exiting.')
               exit(0)

        if len(reads) != len(trims):
            print('yes')
            print >> sys.stderr, "Error: File args need to be the same length"

#        if adaptor_file == "":
#           print ('Adaptor file specified. Exiting.')
#           exit(0)

        if output_file != "":
            prefixname = output_file
        else:
            prefixname = 'Basic_Metrics'

        args = []
        args = (reads, trims, adaptor_file, prefixname)
        return(args)

    def get_basic_stats_trimmed(self, trims):
        """
          Colect information of trimmed reads.
        """
        try:
           if len(trims)==1:
              trim_fastq = reads[0]
              l_list = list()
              with FastqReader(trim_fastq) as f:
                  for i, record in enumerate(f):
                      # Store read length and total length
                      l = len(record)
                      l_list.append(l)

              self.total_read_trim = i
              self.mean_length_trim = np.mean(l_list)

           if len(trims)==2:
              trim_R1_fastq = reads[0]
              trim_R2_fastq = reads[1]
              l_list = list()
              with FastqReader(trim_R1_fastq) as f:
                  for i, record in enumerate(f):
                      # Store read length and total length
                      l = len(record)
                      l_list.append(l)

              self.total_read_trim_R1 = i
              self.mean_length_trim_R1 = np.mean(l_list)

              l_list = list()
              with FastqReader(trim_R2_fastq) as f:
                  for i, record in enumerate(f):
                      # Store read length and total length
                      l = len(record)
                      l_list.append(l)

              self.total_read_trim_R2 = i
              self.mean_length_trim_R2 = np.mean(l_list)

              self.total_read_trim = self.total_read_trim_R1 + self.total_read_trim_R2
              self.mean_length_trim = (self.mean_length_trim_R1 + self.mean_length_trim_R2)/2

           return(self.total_read_trim, self.mean_length_trim) 
        except ValueError: return False
   
    def get_basic_stats_raw(self, reads):
        """
          Colect information of raw reads.
        """
        try:
           if len(reads)==1:
              base = os.path.basename(reads[0])
              sample = os.path.splitext(base)[0].rsplit('.', 2)[0]
              l_list = list()
              quali_dict = defaultdict(int)
              raw_fastq = reads[0]
              with FastqReader(raw_fastq) as f:
                  for i, record in enumerate(f):
                      # Store read length and total length
                      l = len(record)
                      l_list.append(l)
                      # Store all quality
                      for q in record.qualities:
                          quali_dict[q] += 1

              self.total_read = i
              self.total_base = int(np.sum(l_list))
              self.mean_length = np.mean(l_list)
           
              # q20 = bases higher than phred score + 33 (ascii int)
              self.q20_R1 = (sum([v for k, v in quali_dict.items() if ord(k) > 53]) /
                      self.total_base) * 100
              self.q20_R2 = 0
              """ Return a dictionnary with basic metrics.
              """
              
           if len(reads) ==2:
              base = os.path.basename(reads[0])
              sample = os.path.splitext(base)[0].rsplit('.', 2)[0]
              print(sample)
              l_list = list()
              quali_dict = defaultdict(int)
              raw_R1_fastq = reads[0]
              raw_R2_fastq = reads[1]
              with FastqReader(raw_R1_fastq) as f:
                  for i, record in enumerate(f):
                      # Store read length and total length
                      l = len(record)
                      l_list.append(l)
                      # Store all quality
                      for q in record.qualities:
                          quali_dict[q] += 1

              self.total_read_R1 = i
              self.total_base_R1 = int(np.sum(l_list))
              self.mean_length_R1 = np.mean(l_list)

              # q20 = bases higher than phred score + 33 (ascii int)
              self.q20_R1 = (sum([v for k, v in quali_dict.items() if ord(k) > 53]) /
                      self.total_base_R1) * 100

              l_list = list()
              quali_dict = defaultdict(int)

              with FastqReader(raw_R2_fastq) as f:
                  for i, record in enumerate(f):
                      # Store read length and total length
                      l = len(record)
                      l_list.append(l)
                      # Store all quality
                      for q in record.qualities:
                          quali_dict[q] += 1

              self.total_read_R2 = i
              self.total_base_R2 = int(np.sum(l_list))
              self.mean_length_R2 = np.mean(l_list)

              # q20 = bases higher than phred score + 33 (ascii int)
              self.q20_R2 = (sum([v for k, v in quali_dict.items() if ord(k) > 53]) /
                      self.total_base_R2) * 100

              self.total_read = self.total_read_R1 + self.total_read_R2
              self.total_base = self.total_base_R1 + self.total_base_R2
              self.mean_length = (self.mean_length_R1 + self.mean_length_R2)/2

              """ Return a dictionnary with basic metrics.
              """

           stats_dict = dict(
              sample_name=sample,
              total_reads=self.total_read,
              mean_length=self.mean_length,
              tota_base=self.total_base,
              q20_R1=self.q20_R1,
              q20_R2=self.q20_R2,
            )

           return stats_dict
        except ValueError: return False

    def get_adatptor(self, adaptor_file):
        #1. Longest kmer: <adaptor>
        with open(adaptor_file) as f:
            for line in f:
                if re.findall('Longest kmer:[^}]', line):
                   adaptor = re.search('Longest kmer:[^}]*',line).group().split(':')[1].strip()
                   break
        return(adaptor)
	
    def __init__(self, reads = [], trims = []):
       self.rawfastqfile = reads
       self.trimmedfastqfile = trims
   

  
    def write_stats_txt(self, stats_dict, prefixname): 
       """ Write json stats file.
       This file is read by MultiQC to summarize results of the trimming.
       """
       with open(prefixname + ".trim.txt", 'w') as out:
            out.write('sample_name'+'\t'+'total_reads'+'\t'+'mean_length'+'\t'+'tota_base'+'\t'+'q20_R1'+'\t'+'q20_R2'+'\t'+'trimmed_mean_length'+'\t'+'percent trimmed reads'+'\n')
            out.write('\t'.join(str(v) for k, v in stats_dict.items()))
            out.write('\n')


    def write_stats_json(self, stats_dict, prefixname):
        """ Write json stats file.
        This file is read by MultiQC to summarize results of the trimming.
        """
        with open(prefixname + ".trim.json", 'w') as fp:
            json.dump(stats_dict, fp)


if __name__ == '__main__':
    detectatroposfile ='detect.log'
    TR = TrimReport()
    args = TR.get_options()
#   print(args)
    reads = args[0]
    trims= args[1]
    adaptor_file = args[2]
    prefixname = args[3]
    stats_dict = TR.get_basic_stats_raw(reads)
    stat_trim = TR.get_basic_stats_trimmed(trims)
    stats_dict['trimmed_mean_length'] = stat_trim[1]
    stats_dict['percent trimmed reads'] = (stat_trim[0]*100)/stats_dict['total_reads']
#    stats_dict['adaptor'] = TR.get_adatptor(adaptor_file)  # Todo for R1 and R2 
    print(stats_dict)
    TR.write_stats_txt(stats_dict,prefixname)
    

