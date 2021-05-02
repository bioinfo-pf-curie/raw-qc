#!/usr/bin/env python

import numpy as np
import re
import os
import json
from atropos.io.seqio import FastqReader
from optparse import OptionParser
import linecache

class Trimming_Report(object):
    
    def get_options(self):
        usage = "usage: %prog [options] arg"
        parser = OptionParser(usage)
        parser.add_option("--l", "--logs", dest="logs", default="", help="logs of trimming")
        parser.add_option("--tr1", "--trimreport_1", dest="trim_report_1", default="", help="read adaptor sequence from trimming report_1")
        parser.add_option("--tr2", "--trimreport_2", dest="trim_report_2", default="", help="read adaptor sequence from trimming report_2. (Only for trimgalore)")
        parser.add_option("--r1", "--read1", dest="r1_file", default="", help="read data from raed1")
        parser.add_option("--r2", "--read2", dest="r2_file", default="", help="read data from read2")
        parser.add_option("--t1", "--trim1", dest="trim1_file", default="", help="read trim data for read1")
        parser.add_option("--t2", "--trim2", dest="trim2_file", default="", help="read trim data for read2")
        parser.add_option("--u", "--trim_tool", dest="trim_tool", default="", help="specifies adapter trimming tool ['trimgalore', 'atropos', 'fastp'].")
        parser.add_option("--b", "--biological_name", dest="biological_name", default="", help="")
        parser.add_option("--o", "--output_file", dest="output_file", default="")
        ...
        (options, args) = parser.parse_args()
        ...
        args = []
        args = self.check_options(options.logs,options.trim_report_1,options.trim_report_2, options.r1_file, options.r2_file, options.trim1_file, options.trim2_file, options.trim_tool, options.biological_name, options.output_file)
        return(args)
 
    def check_options(self, logs, trim_report_1, trim_report_2, r1_file, r2_file, trim1_file, trim2_file, trim_tool, biological_name, output_file):
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
        elif r1_file != "" and r2_file == "":
                reads = [r1_file]
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
            print ('Should be set one and only one trim data for each read data. Exiting.')
            exit(0)

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

        if biological_name != "":
            biological_name = biological_name
        else:
            base = os.path.basename(reports[0])
            biological_name = os.path.splitext(base)[0].rsplit('.', 2)[0]

        if output_file != "":
            prefixname = output_file
        else:
            prefixname = biological_name 

        args = []
        args = (logs, reports, reads, trims, trim_tool, biological_name, prefixname)
        return(args)

    def get_mean_length_raw(self, reads):
        """
          Store read length for a seed of 1000 reads befor trimming.
        """
        try:
           print(reads)
           if len(reads)==1:
              l_list = list()
              raw_fastq = reads[0]
              print(raw_fastq)
              with FastqReader(raw_fastq) as f:
                  for i, record in enumerate(f,1000):
                      l = len(record)
                      l_list.append(l)

              self.mean_length = np.mean(l_list)


           if len(reads) ==2:
              l_list = list()
              raw_R1_fastq = reads[0]
              raw_R2_fastq = reads[1]
              with FastqReader(raw_R1_fastq) as f:
                  for i, record in enumerate(f,1000):
                      l = len(record)
                      l_list.append(l)

              self.mean_length_R1 = np.mean(l_list)

              l_list = list()
              with FastqReader(raw_R2_fastq) as f:
                  for i, record in enumerate(f,1000):
                      l = len(record)
                      l_list.append(l)


              self.mean_length_R2 = np.mean(l_list)
              self.mean_length = (self.mean_length_R1 + self.mean_length_R2)/2

           return self.mean_length
        except ValueError: return False


    def get_mean_length_trimmed(self, trims):
        """
          Store read length for a seed of 1000 reads after trimming.
        """
        try:
           if len(trims)==1:
              l_list = list()
              trim_fastq = trims[0]
              with FastqReader(trim_fastq) as f:
                  for i, record in enumerate(f,1000):
                      l = len(record)
                      l_list.append(l)

              self.mean_length_trimmed = np.mean(l_list)


           if len(trims) ==2:
              l_list = list()
              trim_R1_fastq = trims[0]
              trim_R2_fastq = trims[1]
              with FastqReader(trim_R1_fastq) as f:
                  for i, record in enumerate(f,1000):
                      l = len(record)
                      l_list.append(l)

              self.mean_length_R1 = np.mean(l_list)

              l_list = list()
              with FastqReader(trim_R2_fastq) as f:
                  for i, record in enumerate(f,1000):
                      l = len(record)
                      l_list.append(l)


              self.mean_length_R2 = np.mean(l_list)
              self.mean_length_trimmed = (self.mean_length_R1 + self.mean_length_R2)/2

           return self.mean_length_trimmed
        except ValueError: return False


    def get_adatptor_trimgalore(self, reports):
        try:
           base = os.path.basename(reports[0])
           sample = os.path.splitext(base)[0].rsplit('.', 3)[0]
           if len(reports)==1:
              l_list = list()
              trim_report = reports[0]
              with open(trim_report) as f:
                 for line in f:
                   if re.findall('Adapter sequence:[^"]', line):
                      self_adapter_seq = re.search('Adapter sequence:[^"]*',line).group().split(':')[1].split('(')[0].strip()
                      l_list.append(self_adapter_seq)
                      try:
                           kit_name = re.search('Adapter sequence:[^"]*',line).group().split('(Illumina')[1].split(',')[0].strip()
                      except IndexError:
                           kit_name = 'unknown'
                      l_list.append(kit_name)

           if len(reports) == 2:
              l_list = list()
              trim_report_1= reports[0]
              trim_report_2 = reports[1]
              ### in paire end we have unique kit_name for R1,R2.
              with open(trim_report_1) as f:
                 for line in f:
                   if re.findall('Adapter sequence:[^"]', line):
                      self_adapter_seq_R1 = re.search('Adapter sequence:[^"]*',line).group().split(':')[1].split('(')[0].strip()
                      l_list.append(self_adapter_seq_R1)
                      try:
                         kit_name = re.search('Adapter sequence:[^"]*',line).group().split('(Illumina')[1].split(',')[0].strip()
                      except IndexError:
                         kit_name = 'unknown'

              with open(trim_report_2) as f:
                 for line in f:
                   if re.findall('Adapter sequence:[^"]', line):
                      self_adapter_seq_R2 = re.search('Adapter sequence:[^"]*',line).group().split(':')[1].split('(')[0].strip()
                      l_list.append(self_adapter_seq_R2)
                      try:
                         kit_name = re.search('Adapter sequence:[^"]*',line).group().split('(Illumina')[1].split(',')[0].strip()
                      except IndexError:
                         kit_name = 'unknown'
                      l_list.append(kit_name)

           adapter_seq_dict = dict(
              sample_name = sample,
              adapter_seq = l_list,
            )
           print(adapter_seq_dict)
           return adapter_seq_dict

        except ValueError: return False

    def get_stat_trimgalore(self, reports, biological_name):
        try:
           base = os.path.basename(reports[0])
           sample = os.path.splitext(base)[0].rsplit('.', 3)[0]
           print(sample)
           l_list = list()
           blocks = []
           if len(reports)==1:
              trim_report = reports[0]
              with open(trim_report) as f:
                for i, line in enumerate(f):
                   if re.findall('Total reads processed:[^"]', line):
                      total_reads = int(re.search('Total reads processed:[^"]*',line).group().split(':')[1].strip().replace(",", ""))
                   if re.findall('Total basepairs processed:', line):
                      total_bases = int(re.search('Total basepairs processed:[^"]*',line).group().split(':')[1].split('bp')[0].strip().replace(",", ""))
                   if re.findall('Quality-trimmed:[^"]', line):
                      q20_reads = 100-float(re.search('Quality-trimmed:[^"]*',line).group().strip().split('(')[1].split(')')[0].split('%')[0])
                   if re.findall('Reads with adapters', line.strip()):
                      trimmed_reads = float(re.search('Reads with adapters:[^"]*',line).group().strip().split('(')[1].split(')')[0].split('%')[0])
                      ##trimmed_reads = float(re.search('^Total written [\$|\W|\s|\S|\w]*',line).group().strip().split(':')[1].split('(')[1].split(')')[0].split('%')[0])
                   if re.findall('Number of sequence pairs removed', line.strip()):
                      discarded_reads = float(re.search('^Number of sequence pairs removed [\$|\W|\s|\S|\w]*',line).group().strip().split(':')[1].split('(')[1].split(')')[0].split('%')[0])
                   else:
                      discarded_reads = 0
                l_list.extend([total_reads, self.mean_length, total_bases, q20_reads, self.mean_length_trimmed, trimmed_reads, discarded_reads])

           if len(reports)==2:
              l_list = list()
              trim_report_1= reports[0]
              trim_report_2 = reports[1]
              with open(trim_report_1) as f:
                for i, line in enumerate(f):
                   if re.findall('Total reads processed:[^"]', line):
                      total_reads_1 = int(re.search('Total reads processed:[^"]*',line).group().split(':')[1].strip().replace(",", ""))
                   if re.findall('Total basepairs processed:', line):
                      total_bases_1 = int(re.search('Total basepairs processed:[^"]*',line).group().split(':')[1].split('bp')[0].strip().replace(",", ""))
                   if re.findall('Reads with adapters', line.strip()):
                      trimmed_reads_1 = float(re.search('Reads with adapters:[^"]*',line).group().strip().split('(')[1].split(')')[0].split('%')[0])
                   if re.findall('Quality-trimmed:[^"]', line):
                      q20_reads1 = 100-float(re.search('Quality-trimmed:[^"]*',line).group().strip().split('(')[1].split(')')[0].split('%')[0])
                   if re.findall('Number of sequence pairs removed', line.strip()):
                      discarded_reads_1 = float(re.search('^Number of sequence pairs removed [\$|\W|\s|\S|\w]*',line).group().strip().split(':')[1].split('(')[1].split(')')[0].split('%')[0])
                   else:
                      discarded_reads_1 = 0

              with open(trim_report_2) as f:
                blocks = []
                for i, line in enumerate(f):
                   if re.findall('Total reads processed:[^"]', line):
                      total_reads_2 = int(re.search('Total reads processed:[^"]*',line).group().split(':')[1].strip().replace(",", ""))
                   #if re.findall('RUN STATISTICS', line.strip()):
                   #   mean_length_2=linecache.getline(trim_report_2, i-1).split('\t')[0]
                   #if re.findall('^[0-9]',line) and not "sequences" in line:
                   #   blocks.append(re.search(r'^[0-9]+',line).group().split(' ')[0])
                   if re.findall('Total basepairs processed:', line):
                      total_bases_2 = int(re.search('Total basepairs processed:[^"]*',line).group().split(':')[1].split('bp')[0].strip().replace(",", ""))
                   if re.findall('Reads with adapters', line.strip()):
                      trimmed_reads_2 = float(re.search('Reads with adapters:[^"]*',line).group().strip().split('(')[1].split(')')[0].split('%')[0])
                   #if re.findall('Quality-trimmed:[^"]', line):
                   #   q20_reads1 = 100-float(re.search('Quality-trimmed:[^"]*',line).group().strip().split('(')[1].split(')')[0].split('%')[0])
                   if re.findall('Quality-trimmed:[^"]', line):
                      q20_reads2 = 100-float(re.search('Quality-trimmed:[^"]*',line).group().strip().split('(')[1].split(')')[0].split('%')[0])
                   if re.findall('Number of sequence pairs removed', line.strip()):
                      discarded_reads_2 = float(re.search('^Number of sequence pairs removed [\$|\W|\s|\S|\w]*',line).group().strip().split(':')[1].split('(')[1].split(')')[0].split('%')[0])
                   else:
                      discarded_reads_2 = 0

              total_reads = total_reads_1 + total_reads_2
              total_bases = total_bases_1 + total_bases_2
              trimmed_reads = float((trimmed_reads_1 + trimmed_reads_2)/2)
              discarded_reads = discarded_reads_1 + discarded_reads_2
              l_list.extend([total_reads, self.mean_length, total_bases, q20_reads1, q20_reads2, self.mean_length_trimmed, trimmed_reads, discarded_reads])

           stat_dict = dict(
              sample_name = sample,
              biological_name = biological_name,
              stat = l_list)
           print(stat_dict)
           return stat_dict

        except ValueError: return False

    def get_adatptor_fastp(self, reports):
        l_list = list()   
        try:
           base = os.path.basename(reports[0])
           sample = os.path.splitext(base)[0].rsplit('.', 2)[0]
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
           print(adapter_seq_dict)
           return adapter_seq_dict
        except ValueError: return False

    def get_stat_fastp(self, logs, length, biological_name):
        try:
           base = os.path.basename(logs)
           sample = os.path.splitext(base)[0].rsplit('_', 1)[0]
           l_list = list()
           read_block = []
           base_block = []
           Q20_block = []
           if length==1:
              with open(logs) as f:
                for i, line in enumerate(f):
                   if re.findall('^total reads:', line):
                      total_reads = int(re.search('^total reads: [0-9]*',line.strip()).group().split(':')[1])
                      read_block.append(total_reads)
                   if re.findall('^total bases:', line):
                      total_bases = int(re.search('^total bases: [0-9]*',line.strip()).group().split(':')[1])
                      base_block.append(total_bases)
                   if re.findall('^Q20 bases:', line):
                      Q20=float(re.search('^Q20 bases: [\$|\W|\s|\S|\w]*',line.strip()).group().split(':')[1].split('(')[1].split(')')[0].split('%')[0])
                      Q20_block.append(Q20)
                   if re.findall('^reads with adapter trimmed:', line):
                      adapt_trimmed = int(re.search('^reads with adapter trimmed: [0-9]*',line.strip()).group().split(':')[1])
                   if re.findall('^reads failed due to low quality:', line):
                      low_qulaity = int(re.search('^reads failed due to low quality: [0-9]*',line.strip()).group().split(':')[1])
                   if re.findall('^reads failed due to too many N:', line):
                      many_N = int(re.search('^reads failed due to too many N: [0-9]*',line.strip()).group().split(':')[1])
                   if re.findall('^reads failed due to too short:', line):
                      too_short = int(re.search('^reads failed due to too short: [0-9]*',line.strip()).group().split(':')[1])

                total_reads = read_block[0]  ##befor_trimming
                total_bases = base_block[0]  ##befor_trimming
                q20_reads1 = Q20_block[1]
                trimmed_reads = (adapt_trimmed/total_reads)*100
                discarded_reads= ((low_qulaity + many_N + too_short)/total_reads)*100
                l_list.extend([total_reads, self.mean_length, total_bases, q20_reads1, self.mean_length_trimmed, trimmed_reads, discarded_reads])

           if length==2:
              with open(logs) as f:
                for i, line in enumerate(f):
                   if re.findall('^total reads:', line):
                      total_reads = int(re.search('^total reads: [0-9]*',line.strip()).group().split(':')[1])
                      read_block.append(total_reads)
                   if re.findall('^total bases:', line):
                      total_bases = int(re.search('^total bases: [0-9]*',line.strip()).group().split(':')[1])
                      base_block.append(total_bases)
                   if re.findall('^Q20 bases:', line):
                      Q20=float(re.search('^Q20 bases: [\$|\W|\s|\S|\w]*',line.strip()).group().split(':')[1].split('(')[1].split(')')[0].split('%')[0])
                      Q20_block.append(Q20) 
                   if re.findall('^reads with adapter trimmed:', line):
                      adapt_trimmed = int(re.search('^reads with adapter trimmed: [0-9]*',line.strip()).group().split(':')[1])
                   if re.findall('^reads failed due to low quality:', line):
                      low_qulaity = int(re.search('^reads failed due to low quality: [0-9]*',line.strip()).group().split(':')[1])
                   if re.findall('^reads failed due to too many N:', line):
                      many_N = int(re.search('^reads failed due to too many N: [0-9]*',line.strip()).group().split(':')[1])
                   if re.findall('^reads failed due to too short:', line):
                      too_short = int(re.search('^reads failed due to too short: [0-9]*',line.strip()).group().split(':')[1])
                total_reads = (read_block[0]+read_block[1])  ##befor_trimming
                total_bases = (base_block[0]+base_block[1]) ##befor_trimming
                q20_reads1 = Q20_block[2]
                q20_reads2 = Q20_block[3]
                trimmed_reads = (adapt_trimmed/total_reads)*100
                discarded_reads= ((low_qulaity + many_N + too_short)/total_reads)*100
                l_list.extend([total_reads, self.mean_length, total_bases, q20_reads1, q20_reads2, self.mean_length_trimmed, trimmed_reads, discarded_reads])
           stat_dict = dict(
              sample_name = sample,
              biological_name = biological_name,
              stat = l_list
           )
           print(stat_dict)
           return stat_dict
        except ValueError: return False


    def get_adatptor_atropos(self, reports):
        l_list = list()
        try:
           base = os.path.basename(reports[0])
           sample = os.path.splitext(base)[0].rsplit('.', 2)[0]
           with open(reports[0]) as json_file:
              data = json.load(json_file)
              if None in (data['input']['input_names']):
                 for key, value in data['trim']['modifiers']['AdapterCutter']['adapters'][0].items():
                     if 'sequence' in value:
                         l_list.append(value['sequence'])

              else:
                 for key, value in data['trim']['modifiers']['AdapterCutter']['adapters'][0].items():
                     if 'sequence' in value:
                         l_list.append(value['sequence'])
                 for key, value in data['trim']['modifiers']['AdapterCutter']['adapters'][1].items():
                     if 'sequence' in value:
                         l_list.append(value['sequence'])
               
           adapter_seq_dict = dict(
              sample_name = sample,
              adapter_seq = l_list
            )
           print(adapter_seq_dict)
           return adapter_seq_dict

        except ValueError: return False
    
    def get_stat_atropos(self, reports, biological_name):
        l_list = list()
        try:
           base = os.path.basename(reports[0])
           sample = os.path.splitext(base)[0].rsplit('_', 2)[0]
           print(base)
           print(sample)
           with open(reports[0]) as json_file:
              data = json.load(json_file)
              if None in (data['input']['input_names']):
                 total_reads = data['total_record_count']
                 ##mean_length = (int(data['derived']['mean_sequence_lengths'][0]))
                 total_bases=int(data['total_bp_counts'][0])+int(data['total_bp_counts'][1])
                 q20_reads1 = (1-(data['trim']['modifiers']['QualityTrimmer']['fraction_bp_trimmed'][0]))*100
                 trimmed_reads=(data['trim']['modifiers']['AdapterCutter']['fraction_records_with_adapters'][0])*100
                 discarded_reads = round(data['trim']['filters']['too_short']['fraction_records_filtered'],4)
                 l_list.extend([total_reads, self.mean_length, total_bases, q20_reads1, self.mean_length_trimmed, trimmed_reads, discarded_reads])
              else:
                 total_reads = data['total_record_count']*2
                 total_bases=int(data['total_bp_counts'][0])+int(data['total_bp_counts'][1])
                 q20_reads1 = (1-(data['trim']['modifiers']['QualityTrimmer']['fraction_bp_trimmed'][0]))*100
                 q20_reads2 = (1-(data['trim']['modifiers']['QualityTrimmer']['fraction_bp_trimmed'][1]))*100
                 trimmed_reads = ((data['trim']['modifiers']['AdapterCutter']['fraction_records_with_adapters'][0]*100)+(data['trim']['modifiers']['AdapterCutter']['fraction_records_with_adapters'][1]*100))/2
                 discarded_reads = round(data['trim']['filters']['too_short']['fraction_records_filtered'],4)
                 l_list.extend([total_reads, self.mean_length, total_bases, q20_reads1, q20_reads2, self.mean_length_trimmed, trimmed_reads, discarded_reads])

           stat_dict = dict(
              sample_name = sample,
              biological_name = biological_name,
              stat = l_list
           )
           print(stat_dict)
           return stat_dict
        except ValueError: return False
 
    def write_adapter_txt(self, adapter_seq_dict, prefixname):
       """ Write json stats file.
       This file is read by MultiQC to summarize results of the trimming.
       """
       for key, value in adapter_seq_dict.items():
           if len(adapter_seq_dict[key]) == 2:
             with open(prefixname + "_Adaptor_seq.trim.txt", 'w') as out:
                out.write('sample_name'+'\t'+"Adapter_sequence_read_1_regular_3'"+'\t' + "kit_name"+'\n')
                out.write(adapter_seq_dict.get('sample_name')+'\t'+'\t'.join(map(str,adapter_seq_dict.get('adapter_seq')))+'\n')
           if len(adapter_seq_dict[key]) == 3:
             with open(prefixname + "_Adaptor_seq.trim.txt", 'w') as out:
                out.write('sample_name'+'\t'+"Adapter_sequence_read_1_regular_3'"+'\t'+"Adapter_sequence_read_2_regular_3'"+ '\t' + "kit_name"+'\n')
                out.write(adapter_seq_dict.get('sample_name')+'\t'+'\t'.join(map(str,adapter_seq_dict.get('adapter_seq')))+'\n')

    def write_stats_txt(self, stats_dict, prefixname):
       """ Write json stats file.
       This file is read by MultiQC to summarize results of the trimming.
        based reads = after trimming
        Q20 = after trimming
        trimmed_reads = %reads with adapter
        discarded_reads = %(low_quality_reads + too_many_N_reads + too_short_reads + too_long_reads)/total_reads_befor_trimming
      
       """
       my_formatted_list = [ '%.2f' % elem for elem in stats_dict.get('stat')]
       for key, value in stats_dict.items():
           if len(stats_dict['stat']) == 7:
             with open(prefixname + "_Basic_Metrics.trim.txt", 'w') as out:
               out.write('Sample_name'+'\t'+'Biological_name'+'\t'+'Total_reads'+'\t'+'Mean_length'+'\t'+'Total_base'+'\t'+'Q20_R1'+'\t'+'Trimmed_Mean_length'+'\t'+'Trimmed_reads'+'\t'+'Discarded_reads'+'\n')
               out.write(stats_dict.get('sample_name')+'\t'+stats_dict.get('biological_name')+'\t'+'\t'.join(map(str, my_formatted_list))+'\n')
   
           if len(stats_dict['stat']) == 8:
             with open(prefixname + "_Basic_Metrics.trim.txt", 'w') as out:
              out.write('Sample_name'+'\t'+'Biological_name'+'\t'+'Total_reads'+'\t'+'Mean_length'+'\t'+'Total_base'+'\t'+'Q20_R1'+'\t'+'Q20_R2'+'\t'+'Trimmed_Mean_length'+'\t'+'Trimmed_reads'+'\t'+'Discarded_reads'+'\n')
              out.write(stats_dict.get('sample_name')+'\t'+stats_dict.get('biological_name')+'\t'+'\t'.join(map(str, my_formatted_list))+'\n')

if __name__ == '__main__':
    TR = Trimming_Report()
    args = TR.get_options()
    logs=args[0]
    reports = args[1]
    reads = args[2]
    trims= args[3]
    trim_tool= args[4]
    biological_name = args[5]
    prefixname = args[6]
    if len(reads)==1:
       length=1
    else:
       length=2
    TR.get_mean_length_raw(reads)
    TR.get_mean_length_trimmed(trims)
    if trim_tool == "trimgalore":
        adapter_seq_dict = TR.get_adatptor_trimgalore(reports)
        stat_dict = TR.get_stat_trimgalore(reports, biological_name)
    if trim_tool == "fastp":
        adapter_seq_dict = TR.get_adatptor_fastp(reports)
        stat_dict = TR.get_stat_fastp(logs, length, biological_name)
    if trim_tool == "atropos":
        adapter_seq_dict = TR.get_adatptor_atropos(reports)
        stat_dict = TR.get_stat_atropos(reports, biological_name)
    TR.write_adapter_txt(adapter_seq_dict,prefixname)
    TR.write_stats_txt(stat_dict,prefixname)
