#!/usr/bin/env python

import numpy as np
import re
import os
import json
import gzip
import argparse
from Bio import SeqIO

def get_options():
    parser = argparse.ArgumentParser()
    parser.add_argument('logs', nargs='+', help="Logs file(s)")
    parser.add_argument("-u", "--trim_tool", default="", help="specifies adapter trimming tool ['trimgalore','fastp'].")
    parser.add_argument("-t", "--atype", default="Adapter", help="Adapter type")
    parser.add_argument("-n", "--name", default="", help="")
    parser.add_argument("-o", "--oprefix", default="")
    args = parser.parse_args()
    return(args)


def simplify(s):
    if len(s) > 100:
        output=''
        counts=1
        for i in range(len(s)- 1):
            if s[i] == s[i+1]:
                counts+=1
            else:
                if counts==1:
                    output+=s[i]
                else:
                    output+=s[i]+"{"+str(counts)+"}"
                    counts=1

        if counts == 1:
            output+=s[i+1]
        else:
            output+=s[i+1]+"{"+str(counts)+"}"
        return output
    else:
        return s

 
def get_trimgalore_summary(logs, sample_name):
    """"
    Extract statistics from trimGalore logs file
    For paired-end data, trimgalore generates 2 log files (one per read)
    """
    base = os.path.basename(logs[0])
    adapter_seq = trimmed_reads = None
    qual_reads = too_short = 0
    stats_list=()
 
    with open(logs[0]) as f:
        for i, line in enumerate(f):
            if re.findall('Adapter sequence', line) and adapter_seq is None:
                adapter_seq = re.search('Adapter sequence:[^"]*',line).group().split(':')[1].strip()#.split('(')[0].strip()
                adapter_seq = re.sub("'","",adapter_seq)
            if re.findall('Sequence:[^"]*', line) and adapter_seq is None:
                adapter_seq = re.search('Sequence:[^"]*',line).group().split(';')[0].split(':')[1].strip()
            if re.findall('Quality-trimmed:[^"]', line):
                qual_reads = float(re.search('Quality-trimmed:[^"]*',line).group().strip().split('(')[1].split(')')[0].split('%')[0])
            if re.findall('Reads with adapters', line.strip()):
                trimmed_reads = float(re.search('Reads with adapters:[^"]*',line).group().strip().split('(')[1].split(')')[0].split('%')[0])
            if re.findall('Sequences removed', line.strip()):
                too_short = float(re.search('^Sequences removed [\$|\W|\s|\S|\w]*',line).group().strip().split(':')[1].split('(')[1].split(')')[0].split('%')[0])
    stats_list=[qual_reads, trimmed_reads, too_short]
    out_list = dict(sample_name = sample_name, adapter = simplify(adapter_seq), stat = stats_list)

    if len(logs)==2:
        adapter_seq_2 = trimmed_reads_2 = 'NA'
        qual_reads_2 = 0
        adapter_seq_2 = None
        with open(logs[1]) as f:
            for i, line in enumerate(f):
                if re.findall('Adapter sequence', line) and adapter_seq_2 is None:
                    adapter_seq_2 = re.search('Adapter sequence:[^"]*',line).group().split(':')[1].strip()
                    adapter_seq_2 = re.sub("'","",adapter_seq_2)
                if re.findall('Sequence:[^"]*', line) and adapter_seq_2 is None:
                    adapter_seq_2 = re.search('Sequence:[^"]*',line).group().split(';')[0].split(':')[1].strip()
                if re.findall('Reads with adapters', line.strip()):
                    trimmed_reads_2 = float(re.search('Reads with adapters:[^"]*',line).group().strip().split('(')[1].split(')')[0].split('%')[0])
                if re.findall('Quality-trimmed:[^"]', line):
                    qual_reads_2 = float(re.search('Quality-trimmed:[^"]*',line).group().strip().split('(')[1].split(')')[0].split('%')[0])
                if re.findall('Number of sequence pairs removed', line.strip()):
                    too_short = float(re.search('^Number of sequence pairs removed [\$|\W|\s|\S|\w]*',line).group().strip().split(':')[1].split('(')[1].split(')')[0].split('%')[0])

            #trimmed_reads = "{:.2f}".format(float((trimmed_reads + trimmed_reads_2)/2))
            #discarded_reads = discarded_reads + discarded_reads_2
        stats_list=[qual_reads, qual_reads_2, trimmed_reads, trimmed_reads_2, too_short]
        out_list = dict(sample_name = sample_name, adapter = simplify(adapter_seq), adapter_2 = simplify(adapter_seq_2), stat = stats_list)

    return(out_list)

def get_cutadapt_summary(logs, sample_name):
    """"
    Extract statistics from cutadapt logs file
    For paired-end data, a single log file is parsed
    """
    base = os.path.basename(logs[0])
    adapter_seq = trimmed_reads = None
    adapter_seq_2 = trimmed_reads_2 = total_base = None
    qual_reads = qual_reads_2  = too_short = 0
    stats_list=()
 
    with open(logs[0]) as f:
        for i, line in enumerate(f):
            if re.findall('Sequence:[^"]*', line) and adapter_seq is None:
                adapter_seq = re.search('Sequence:[^"]*',line).group().split(';')[0].split(':')[1].strip()
            elif re.findall('Sequence:[^"]*', line) and adapter_seq is not None:
                adapter_seq_2 = re.search('Sequence:[^"]*',line).group().split(';')[0].split(':')[1].strip()
            if re.findall('Total basepairs processed:[^"]', line):
                total_base=int(re.search('^Total basepairs processed:[^"]*',line).group().split(":")[1].strip().replace(" bp","").replace(",",""))
            if re.findall('Quality-trimmed:[^"]', line):
                qual_reads = float(re.search('Quality-trimmed:[^"]*',line).group().strip().split('(')[1].split(')')[0].split('%')[0])
                qual_r1=re.search('Read 1:[^"]*',next(f))
                if qual_r1 and total_base is not None:
                    qual_r1=int(qual_r1.group().split(":")[1].strip().replace(" bp","").replace(",",""))
                    qual_reads="{:.2f}".format(float((qual_r1 *100 / total_base)))
                    qual_r2=re.search('Read 2:[^"]*',next(f))
                    if qual_r2 and total_base is not None:
                        qual_r2=int(qual_r2.group().split(":")[1].strip().replace(" bp","").replace(",",""))
                        qual_reads_2="{:.2f}".format(float((qual_r1 *100 / total_base)))
            if re.findall('Reads with adapters:', line.strip()):
                trimmed_reads = float(re.search('Reads with adapters:[^"]*',line).group().strip().split('(')[1].split(')')[0].split('%')[0])
            if re.findall('Read 1 with adapter:', line.strip()):
                trimmed_reads = float(re.search('Read 1 with adapter:[^"]*',line).group().strip().split('(')[1].split(')')[0].split('%')[0])
            if re.findall('Read 2 with adapter:', line.strip()):
                trimmed_reads_2 = float(re.search('Read 2 with adapter:[^"]*',line).group().strip().split('(')[1].split(')')[0].split('%')[0])
            if re.findall('Reads that were too short:', line.strip()):
                too_short = float(re.search('^Reads that were too short: [^"]*',line).group().strip().split(':')[1].split('(')[1].split(')')[0].split('%')[0])
            if re.findall('Pairs that were too short:', line.strip()):
                too_short = float(re.search('^Pairs that were too short: [^"]*',line).group().strip().split(':')[1].split('(')[1].split(')')[0].split('%')[0])
 
    ## single-end
    if adapter_seq_2 is None and trimmed_reads_2 is None:
        stats_list=[qual_reads, trimmed_reads, too_short]
        out_list = dict(sample_name = sample_name, adapter = simplify(adapter_seq), stat = stats_list)
    else:
        stats_list=[qual_reads, qual_reads_2, trimmed_reads, trimmed_reads_2, too_short]
        out_list = dict(sample_name = sample_name, adapter = simplify(adapter_seq), adapter_2 = simplify(adapter_seq_2), stat = stats_list)

    return(out_list)


#    def get_adatptor_fastp(self, reports):
#        l_list = list()   
#        try:
#           base = os.path.basename(reports[0])
#           sample = os.path.splitext(base)[0].rsplit('.', 2)[0]
#           with open(reports[0]) as json_file:
#              data = json.load(json_file)
#              if 'adapter_cutting' not in data:
#                 l_list.append("None")

#              else:
#                 if 'read1_adapter_sequence' in data['adapter_cutting']:
#                    self_adapter_seq_R1 = data['adapter_cutting']['read1_adapter_sequence']
#                 else:
#                    self_adapter_seq_R1 = ""

#                 if 'read2_adapter_sequence' in data['adapter_cutting']:
#                    self_adapter_seq_R2 = data['adapter_cutting']['read2_adapter_sequence']
#                 else:
#                    self_adapter_seq_R2 = ""
                 
#                 l_list.append(self_adapter_seq_R1)
#                 l_list.append(self_adapter_seq_R2)

#           adapter_seq_dict = dict(
#              sample_name = sample,
#              adapter_seq = l_list
#           )
#           print(adapter_seq_dict)
#           return adapter_seq_dict
#        except ValueError: return False

    def get_stat_fastp(self, logs, length, biological_name):
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
#                total_reads = read_block[0]  ##befor_trimming
                total_bases = base_block[0]  ##befor_trimming
                q20_reads1 = Q20_block[1]
                trimmed_reads = (adapt_trimmed/total_reads)*100
                discarded_reads= ((low_qulaity + many_N + too_short)/total_reads)*100
                l_list.extend([total_reads, self.mean_length, total_bases, q20_reads1, self.mean_length_trimmed, trimmed_reads, discarded_reads])
#           if length==2:
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

 
def write_summary(stats_dict, atype, oprefix):
    """ 
    Write tsv stats file.
    This file is read by MultiQC to summarize results of the trimming.
    """
    #my_formatted_list = [ '%.2f' % elem for elem in stats_dict.get('stat')]
    my_formatted_list = stats_dict.get('stat')
    for key, value in stats_dict.items():
        if len(stats_dict['stat']) == 3:
            with open(oprefix + "_metrics.trim.tsv", 'w') as out:
                out.write('Sample_id'+'\t'+'Adapter'+'\t'+'Qual_trimmed'+'\t'+'Trimmed_reads'+'\t'+'Too_short'+'\n')
                out.write(stats_dict.get('sample_name') + " [" + atype + "]" + 
                          '\t'+stats_dict.get('adapter')+'\t'+'\t'.join(map(str, my_formatted_list))+'\n')
  
        if len(stats_dict['stat']) == 5:
            with open(oprefix + "_metrics.trim.tsv", 'w') as out:
                out.write('Sample_id'+'\t'+'Adapter'+'\t'+'Adapter_2'+'\t'+'Qual_trimmed'+'\t'+'Qual_trimmed_2'+'\t'+'Trimmed_reads'+'\t'+'Trimmed_reads_2'+'\t'+'Too_short'+'\n')
                out.write(stats_dict.get('sample_name')+ " [" + atype +"]" +
                          '\t'+stats_dict.get('adapter')+'\t'+stats_dict.get('adapter_2')+'\t'+'\t'.join(map(str, my_formatted_list))+'\n')

if __name__ == '__main__':
    args = get_options()
    
    if args.trim_tool == "trimgalore":
        summary_dict = get_trimgalore_summary(args.logs, sample_name=args.name)
    elif args.trim_tool == "cutadapt":
        summary_dict = get_cutadapt_summary(args.logs, sample_name=args.name)
    elif args.trim_tool == "fastp":
        summary_dict = get_fastp_summary(args.logs, sample_name=args.name)

    print(summary_dict)
    write_summary(summary_dict, atype=args.atype, oprefix=args.oprefix)
