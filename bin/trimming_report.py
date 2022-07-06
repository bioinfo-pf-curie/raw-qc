#!/usr/bin/env python

import numpy as np
import re
import os
import json
from optparse import OptionParser
import gzip
from Bio import SeqIO

def get_options():
    usage = "usage: %prog [options] arg"
    parser = OptionParser(usage)
    parser.add_option("-l", "--logs", dest="logs", default="", help="logs of trimming")
    parser.add_option("-r", "--trimreport_1", dest="trim_report_1", default="", help="read adaptor sequence from trimming report_1")
    parser.add_option("-R", "--trimreport_2", dest="trim_report_2", default="", help="read adaptor sequence from trimming report_2. (Only for trimgalore)")
    parser.add_option("-u", "--trim_tool", dest="trim_tool", default="", help="specifies adapter trimming tool ['trimgalore','fastp'].")
    parser.add_option("-t", "--type", dest="atype", default="", help="unknown")
    parser.add_option("-n", "--name", dest="name", default="", help="")
    parser.add_option("-o", "--oprefix", dest="oprefix", default="")
    ...
    (options, args) = parser.parse_args()
    ...
    args = []
    args = check_options(options.logs,
                         options.trim_report_1, options.trim_report_2, 
                         options.trim_tool,
                         options.atype,
                         options.name,
                         options.oprefix)
    return(args)
    
def check_options(logs, trim_report_1, trim_report_2, trim_tool, atype, name, oprefix):
    """
    Check arguments in command lign.
    """
    if trim_tool == "" and trim_tool != "trimgalore" and trim_tool != "fastp":
        print ('Invalid trimming tool option. Valid options: trimgalore, fastp. Exiting.')
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

    if name == "":
        base = os.path.basename(reports[0])
        name = os.path.splitext(base)[0].rsplit('.', 2)[0]

    args = {'logs':logs, 'reports':reports, 'trim_tool':trim_tool, 
            'atype': atype, 'name':name, 'oprefix':oprefix}
    return(args)


def get_cutadapt_summary(reports, sample_name, tool="cutadapt"):
    """"
    Extract statistics from trimGalore logs file
    """
    base = os.path.basename(reports[0])
    adapter_seq = total_reads = total_bases = trimmed_reads = 'NA'
    qual_reads = discarded_reads = 0
    stats_list=()
    adapter_seq=None
 
    with open(reports[0]) as f:
        for i, line in enumerate(f):
            if tool == 'trimgalore' and re.findall('Adapter sequence', line) and adapter_seq is None:
                adapter_seq = re.search('Adapter sequence:[^"]*',line).group().split(':')[1].strip()#.split('(')[0].strip()
                adapter_seq = re.sub("'","",adapter_seq)
            elif re.findall('Sequence:[^"]*', line) and adapter_seq is None:
                adapter_seq = re.search('Sequence:[^"]*',line).group().split(';')[0].split(':')[1].strip()
            #if re.findall('Total reads processed:[^"]', line):
            #    total_reads = int(re.search('Total reads processed:[^"]*',line).group().split(':')[1].strip().replace(",", ""))
            #if re.findall('Total basepairs processed:', line):
            #    total_bases = int(re.search('Total basepairs processed:[^"]*',line).group().split(':')[1].split('bp')[0].strip().replace(",", ""))
            if re.findall('Quality-trimmed:[^"]', line):
                qual_reads = float(re.search('Quality-trimmed:[^"]*',line).group().strip().split('(')[1].split(')')[0].split('%')[0])
            if re.findall('Reads with adapters', line.strip()):
                trimmed_reads = float(re.search('Reads with adapters:[^"]*',line).group().strip().split('(')[1].split(')')[0].split('%')[0])
            if re.findall('Number of sequence pairs removed', line.strip()):
                discarded_reads = float(re.search('^Number of sequence pairs removed [\$|\W|\s|\S|\w]*',line).group().strip().split(':')[1].split('(')[1].split(')')[0].split('%')[0])
    stats_list=[qual_reads, trimmed_reads, discarded_reads]
    out_list = dict(sample_name = sample_name, adapter = adapter_seq, stat = stats_list)

    if len(reports)==2:
        adapter_seq_2 = total_reads_2 = total_bases_2 = trimmed_reads_2 = 'NA'
        qual_reads_2 = discarded_reads_2 = 0
        with open(reports[1]) as f:
            for i, line in enumerate(f):
                if re.findall(adapter_pattern, line):
                    adapter_seq_2 = re.search(adapter_pattern,line).group().split(':')[1].split('(')[0].strip()
                #if re.findall('Total reads processed:[^"]', line):
                #    total_reads_2 = int(re.search('Total reads processed:[^"]*',line).group().split(':')[1].strip().replace(",", ""))
                #if re.findall('Total basepairs processed:', line):
                #    total_bases_2 = int(re.search('Total basepairs processed:[^"]*',line).group().split(':')[1].split('bp')[0].strip().replace(",", ""))
                if re.findall('Reads with adapters', line.strip()):
                    trimmed_reads_2 = float(re.search('Reads with adapters:[^"]*',line).group().strip().split('(')[1].split(')')[0].split('%')[0])
                if re.findall('Quality-trimmed:[^"]', line):
                    qual_reads_2 = 100-float(re.search('Quality-trimmed:[^"]*',line).group().strip().split('(')[1].split(')')[0].split('%')[0])
                if re.findall('Number of sequence pairs removed', line.strip()):
                    discarded_reads_2 = float(re.search('^Number of sequence pairs removed [\$|\W|\s|\S|\w]*',line).group().strip().split(':')[1].split('(')[1].split(')')[0].split('%')[0])
 
            #total_bases = total_bases_1 + total_bases_2
            trimmed_reads = float((trimmed_reads_1 + trimmed_reads_2)/2)
            discarded_reads = discarded_reads_1 + discarded_reads_2
        stats_list=[qual_reads, qual_reads_2, trimmed_reads, discarded_reads]
        out_list = dict(sample_name = sample_name, adapter = adapter_seq, adapter_2 = adapter_seq_2, stat = stats_list)

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

#    def get_stat_fastp(self, logs, length, biological_name):
#        try:
#           base = os.path.basename(logs)
#           sample = os.path.splitext(base)[0].rsplit('_', 1)[0]
#           l_list = list()
#           read_block = []
#           base_block = []
#           Q20_block = []
#           if length==1:
#              with open(logs) as f:
#                for i, line in enumerate(f):
#                   if re.findall('^total reads:', line):
#                      total_reads = int(re.search('^total reads: [0-9]*',line.strip()).group().split(':')[1])
#                      read_block.append(total_reads)
#                   if re.findall('^total bases:', line):
#                      total_bases = int(re.search('^total bases: [0-9]*',line.strip()).group().split(':')[1])
#                      base_block.append(total_bases)
#                   if re.findall('^Q20 bases:', line):
#                      Q20=float(re.search('^Q20 bases: [\$|\W|\s|\S|\w]*',line.strip()).group().split(':')[1].split('(')[1].split(')')[0].split('%')[0])
#                      Q20_block.append(Q20)
#                   if re.findall('^reads with adapter trimmed:', line):
#                      adapt_trimmed = int(re.search('^reads with adapter trimmed: [0-9]*',line.strip()).group().split(':')[1])
#                   if re.findall('^reads failed due to low quality:', line):
#                      low_qulaity = int(re.search('^reads failed due to low quality: [0-9]*',line.strip()).group().split(':')[1])
#                   if re.findall('^reads failed due to too many N:', line):
#                      many_N = int(re.search('^reads failed due to too many N: [0-9]*',line.strip()).group().split(':')[1])
#                   if re.findall('^reads failed due to too short:', line):
#                      too_short = int(re.search('^reads failed due to too short: [0-9]*',line.strip()).group().split(':')[1])

#                total_reads = read_block[0]  ##befor_trimming
#                total_bases = base_block[0]  ##befor_trimming
#                q20_reads1 = Q20_block[1]
#                trimmed_reads = (adapt_trimmed/total_reads)*100
#                discarded_reads= ((low_qulaity + many_N + too_short)/total_reads)*100
#                l_list.extend([total_reads, self.mean_length, total_bases, q20_reads1, self.mean_length_trimmed, trimmed_reads, discarded_reads])

#           if length==2:
#              with open(logs) as f:
#                for i, line in enumerate(f):
#                   if re.findall('^total reads:', line):
#                      total_reads = int(re.search('^total reads: [0-9]*',line.strip()).group().split(':')[1])
#                      read_block.append(total_reads)
#                   if re.findall('^total bases:', line):
#                      total_bases = int(re.search('^total bases: [0-9]*',line.strip()).group().split(':')[1])
#                      base_block.append(total_bases)
#                   if re.findall('^Q20 bases:', line):
#                      Q20=float(re.search('^Q20 bases: [\$|\W|\s|\S|\w]*',line.strip()).group().split(':')[1].split('(')[1].split(')')[0].split('%')[0])
#                      Q20_block.append(Q20) 
#                   if re.findall('^reads with adapter trimmed:', line):
#                      adapt_trimmed = int(re.search('^reads with adapter trimmed: [0-9]*',line.strip()).group().split(':')[1])
#                   if re.findall('^reads failed due to low quality:', line):
#                      low_qulaity = int(re.search('^reads failed due to low quality: [0-9]*',line.strip()).group().split(':')[1])
#                   if re.findall('^reads failed due to too many N:', line):
#                      many_N = int(re.search('^reads failed due to too many N: [0-9]*',line.strip()).group().split(':')[1])
#                   if re.findall('^reads failed due to too short:', line):
#                      too_short = int(re.search('^reads failed due to too short: [0-9]*',line.strip()).group().split(':')[1])
#                total_reads = (read_block[0]+read_block[1])  ##befor_trimming
#                total_bases = (base_block[0]+base_block[1]) ##befor_trimming
#                q20_reads1 = Q20_block[2]
#                q20_reads2 = Q20_block[3]
#                trimmed_reads = (adapt_trimmed/total_reads)*100
#                discarded_reads= ((low_qulaity + many_N + too_short)/total_reads)*100
#                l_list.extend([total_reads, self.mean_length, total_bases, q20_reads1, q20_reads2, self.mean_length_trimmed, trimmed_reads, discarded_reads])
#           stat_dict = dict(
#              sample_name = sample,
#              biological_name = biological_name,
#              stat = l_list
#           )
#           print(stat_dict)
#           return stat_dict
#        except ValueError: return False
 
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
                out.write('Sample_id'+'\t'+'Adapter'+'\t'+'Qual_trimmed'+'\t'+'Trimmed_reads'+'\t'+'Discarded_reads'+'\n')
                out.write(stats_dict.get('sample_name') + " [" + atype + "]" + 
                          '\t'+stats_dict.get('adapter')+'\t'+'\t'.join(map(str, my_formatted_list))+'\n')
  
        if len(stats_dict['stat']) == 4:
            with open(oprefix + "_metrics.trim.tsv", 'w') as out:
                out.write('Sample_id'+'\t'+'Adapter'+'\t'+'Adapter_2'+'\t'+'Qual_trimmed'+'\t'+'Qual_trimmed_2'+'\t'+'Trimmed_reads'+'\t'+'Discarded_reads'+'\n')
                out.write(stats_dict.get('sample_name')+ " [" + atype +"]" +
                          '\t'+stats_dict.get('adapter')+'\t'+atype+'\t'+stats_dict.get('adapter_2')+'\t'.join(map(str, my_formatted_list))+'\n')

if __name__ == '__main__':
    args = get_options()
    
    if args['trim_tool'] == "trimgalore" or args['trim_tool'] == "cutadapt":
        summary_dict = get_cutadapt_summary(args['reports'], sample_name=args['name'], tool=args['trim_tool'])
    elif args['trim_tool'] == "fastp":
        summary_dict = get_fastp_summary(args['reports'])

    print(summary_dict)
    write_summary(summary_dict, atype=args['atype'], oprefix=args['oprefix'])
