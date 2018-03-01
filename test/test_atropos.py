import filecmp
import os

from rawqc import Atropos
from rawqc.utils import TempFile, rawqc_data


def test_atropos():
    fastq1 = rawqc_data('subsample.R1.fastq.gz')
    fastq2 = rawqc_data('subsample.R2.fastq.gz')

    atrps = Atropos(fastq1, fastq2)

    known_seq = [
        'GATCGGAAGAGCACACGTCTGAACTCCAGTCACCTTGTAATCTCGTATGCCGTCTTCTGCTTG',
        'AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT'
    ]
    guessed_seq = atrps.guess_adapters(max_read=1000, algorithm='heuristic')
    for known, guessed in zip(known_seq, guessed_seq):
        assert known == guessed['sequence']

def test_atropos_remove_adapters():
    filout1 = TempFile('.fastq.gz')
    filout2 = TempFile('.fastq.gz')
    logfile = TempFile('.log')

    fastq1 = rawqc_data('subsample.R1.fastq.gz')
    fastq2 = rawqc_data('subsample.R2.fastq.gz')
    known_seq = {
        '-a': 'GATCGGAAGAGCACACGTCTGAACTCCAGTCACCTTGTAATCTCGTATGCCGTCTTCTGCTTG',
        '-A': 'AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT'
    }

    atrps = Atropos(fastq1, fastq2, logfile=logfile)
    atrps.adapters = known_seq
    atrps.remove_adapters(filout1.name, filout2.name)

    with TempFile('.json') as fout:
        atrps.write_stats_json(fout.name)
        assert filecmp.cmp(fout.name, rawqc_data('atropos.json'))

    filout1.delete()
    filout2.delete()
    logfile.delete()
