#!/usr/bin/env python

import numpy as np
import re
import os
import json
from collections import defaultdict
from atropos.io.seqio import FastaReader
from optparse import OptionParser

class Adapter_seq_Report(object):
    
    def get_options(self):
        usage = "usage: %prog [options] arg"
        parser = OptionParser(usage)
        parser.add_option("--tr1", "--trimreport_1", dest="trim_report_1", default="", help="read adaptor sequence from trimming report_1")
        parser.add_option("--tr2", "--trimreport_2", dest="trim_report_2", default="", help="read adaptor sequence from trimming report_2. (Only for trimgalore)")
        parser.add_option("--u", "--trim_tool", dest="trim_tool", default="", help="specifies adapter trimming tool ['trimgalore', 'atropos', 'fastp'].")
        parser.add_option("--o", "--output_file", dest="output_file", default="")
        ...
        (options, args) = parser.parse_args()
        ...
      ##  print(options, args)
        args = []
        args = self.check_options(options.trim_report_1,options.trim_report_2, options.trim_tool, options.output_file)
        return(args)
 
    def check_options(self, trim_report_1, trim_report_2, trim_tool, output_file):
        """
          Check arguments in command lign.
        """
        
        if trim_tool == "" and trim_tool != "atropos" and trim_tool != "trimgalore" and trim_tool != "fastp":
           print ('Invalid trimming tool option. Valid options: trimgalore, atropos, fastp. Exiting.')
           exit(0)

        if trim_report_1 != "" and trim_report_2 != "" and trim_tool == "fastp":
           print ('Should be specified only one file json for fastp. Exiting.')
           exit(0)

        if trim_report_1 == "" and trim_report_2 != "":
           print ('no trimming report specified for trimming report 1. Exiting.')
           exit(0)

        if trim_report_1 != "" and trim_report_2 != "":
           reports = [trim_report_1, trim_report_2]

        if trim_report_1 != "" and trim_report_2 == "":
           reports = [trim_report_1]

        if output_file != "":
            prefixname = output_file
        else:
            prefixname = 'adaptor_seq'

        args = []
        args = (reports, trim_tool, prefixname)
        return(args)


    def get_adatptor_trimgalore(self, reports):
        #1. Longest kmer: <adaptor>
        #Adapter sequence: 'AGATCGGAAGAGC' (Illumina TruSeq, Sanger iPCR; auto-detected)
        l_list = list()
        try:
           if len(reports)==1:
              base = os.path.basename(reports[0])
              sample = os.path.splitext(base)[0].rsplit('.', 2)[0]
              l_list = list()
              trim_report = reports[0]
              with open(trim_report) as f:
                 for line in f:
                   if re.findall('Adapter sequence:[^"]', line):
                      self_adapter_seq = re.search('Adapter sequence:[^"]*',line).group().split(':')[1].split('(')[0].strip()
                      l_list.append(self_adapter_seq)

           if len(reports) == 2:
              base = os.path.basename(reports[0])
              sample = os.path.splitext(base)[0].rsplit('.', 2)[0]
              l_list = list()
              trim_report_1= reports[0]
              trim_report_2 = reports[1]
              with open(trim_report_1) as f:
                 for line in f:
                   if re.findall('Adapter sequence:[^"]', line):
                      self_adapter_seq_R1 = re.search('Adapter sequence:[^"]*',line).group().split(':')[1].split('(')[0].strip()
                      l_list.append(self_adapter_seq_R1)

              with open(trim_report_2) as f:
                 for line in f:
                   if re.findall('Adapter sequence:[^"]', line):
                      self_adapter_seq_R2 = re.search('Adapter sequence:[^"]*',line).group().split(':')[1].split('(')[0].strip()
                      l_list.append(self_adapter_seq_R2)

           adapter_seq_dict = dict(
              sample_name = sample,
              adapter_seq = l_list
            )

           return adapter_seq_dict

        except ValueError: return False
    
    def get_adatptor_fastp(self, reports):
        l_list = list()   
        try:
           base = os.path.basename(reports[0])
           sample = os.path.splitext(base)[0].rsplit('.', 2)[0]
           print(sample)
           with open(reports[0]) as json_file:
              data = json.load(json_file)
              if 'adapter_cutting' not in data:
                 l_list.append("None")

              else:
                 if 'read1_adapter_sequence' in data['adapter_cutting']:
                    self_adapter_seq_R1 = data['adapter_cutting']['read1_adapter_sequence']
                 else:
                    self_adapter_seq_R1 = ""

                 if 'read2_adapter_sequence' in data['adapter_cutting']:
                    self_adapter_seq_R2 = data['adapter_cutting']['read2_adapter_sequence']
                 else:
                    self_adapter_seq_R2 = ""
                 
                 l_list.append(self_adapter_seq_R1)
                 l_list.append(self_adapter_seq_R2)

           adapter_seq_dict = dict(
              sample_name = sample,
              adapter_seq = l_list
           )
           return adapter_seq_dict
        except ValueError: return False

    def get_adatptor_atropos(self, reports):
        ##1. Longest kmer: CTGTCTCTTATACACATCTCCGAGCCCACGAGACAGTCAGACGAATCTCG
        l_list = list()
        try:
           if len(reports)==1:
              base = os.path.basename(reports[0])
              sample = os.path.splitext(base)[0].rsplit('.', 2)[0]
              l_list = list()
              trim_report = reports[0]
              with FastaReader(trim_report) as f:
                  for i, record in enumerate(f):
                      l_list.append(record.sequence)


           if len(reports) == 2:
              base = os.path.basename(reports[0])
              sample = os.path.splitext(base)[0].rsplit('.', 2)[0]
              l_list = list()
              trim_report_1= reports[0]
              trim_report_2 = reports[1]
              print('*****')
              with FastaReader(trim_report_1) as f:
                  for i, record in enumerate(f):
                      l_list.append(record.sequence)


              with FastaReader(trim_report_2) as f:
                  for i, record in enumerate(f):
                      l_list.append(record.sequence)

           adapter_seq_dict = dict(
              sample_name = sample,
              adapter_seq = l_list
            )

           return adapter_seq_dict

        except ValueError: return False


    def write_stats_txt(self, adapter_seq_dict, prefixname):
       """ Write json stats file.
       This file is read by MultiQC to summarize results of the trimming.
       """
       for key, value in adapter_seq_dict.items():
           if len(adapter_seq_dict[key]) == 1:
               print(adapter_seq_dict)
               with open(prefixname + ".trim.txt", 'w') as out:
                   out.write('sample_name'+'\t'+'Adapter sequence read 1 '+'\n')
                   out.write(adapter_seq_dict.get('sample_name')+'\t'+'\t'.join(map(str,adapter_seq_dict.get('adapter_seq'))))
           if len(adapter_seq_dict[key]) == 2:
               with open(prefixname + ".trim.txt", 'w') as out:
                   out.write('sample_name'+'\t'+'Adapter sequence read 1 '+'\t'+'Adapter sequence read 2'+'\n')
                   out.write(adapter_seq_dict.get('sample_name')+'\t'+'\t'.join(map(str,adapter_seq_dict.get('adapter_seq'))))


if __name__ == '__main__':
    AR = Adapter_seq_Report()
    args = AR.get_options()
    reports = args[0]
    trim_tool= args[1]
    prefixname = args[2]
    if trim_tool == "trimgalore":
    	adapter_seq_dict = AR.get_adatptor_trimgalore(reports)
    if trim_tool == "fastp":
        adapter_seq_dict = AR.get_adatptor_fastp(reports)
    if trim_tool == "atropos":
        adapter_seq_dict = AR.get_adatptor_atropos(reports)

    AR.write_stats_txt(adapter_seq_dict,prefixname)

