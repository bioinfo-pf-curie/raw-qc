# coding: utf-8
#
#  This file is part of Autotropos software
#
#  Copyright (c) 2017 - Institut Curie
#
#  File author(s):
#      Dimitri Desvillechabrol <dimitri.desvillechabrol@curie.fr>,
#
#  Distributed under the terms of the 3-clause BSD license.
#  The full license is in the LICENSE file, distributed with this software.
#
##############################################################################
""" Utilities to manipulate FastQ and Reads.
It uses the FastqReader implemented in Atropos module. FastxFile has shown some
errors while handling gzip files created with zlib (e.g. from atropos).
"""
import numpy as np
from collections import defaultdict

from atropos.io.seqio import FastqReader


class BasicStats(object):
    """ Parse FastQ files to compute some basic statistics and plot.

    Similarly to some information of FastQC tools, we scan FastQ and generates
    a JSON file with all basic statistics of sequencing. The interest is that
    we'll able integrate this JSON in a basic statistics table in MultiQC
    report.
    """
    def __init__(self, filename, max_sample=500000):
        """.. rubric:: constructor

        :param str filename: FastQ filename of the R1 or single-ends.
        :param int max_sample: Large files will not fit in memory. We therefore
            restrict the number of reads to be used for some of the statistics
            to 500,000. This also reduces the amount of time required to get a
            parsed tough. This is required for instance to get the number of
            nucleotides.
        """
        self._filename = filename
        self.max_sample = max_sample
        self._get_basic_stats()

    @property
    def filename(self):
        """ Get the filename.
        """
        return self._filename

    def _get_basic_stats(self):
        """Populates the data structures for JSON file or plotting.
        """
        # Init variable
        stats = {'A': 0, 'C': 0, 'G': 0, 'T': 0, 'N': 0}
        quali_dict = defaultdict(int)
        l_list = list()
        gc_list = list()

        with FastqReader(self.filename) as f:
            for i, record in enumerate(f):
                # Store read length and total length
                l = len(record)
                l_list.append(l)

                # Store GC content
                if i < self.max_sample:
                    g_count = record.sequence.count('G')
                    c_count = record.sequence.count('C')
                    if l > 0:
                        gc_list.append(((g_count + c_count) / float(l)) * 100)

                # Store all quality
                for q in record.qualities:
                    quali_dict[q] += 1

        self.total_read = i
        self.total_base = int(np.sum(l_list))
        self.mean_length = np.mean(l_list)
        self.gc_content = np.mean(gc_list)
        # q20 = bases higher than phred score + 33 (ascii int)
        self.q20 = (sum([v for k, v in quali_dict.items() if ord(k) > 53]) /
                    self.total_base) * 100
        self.stats = stats

    def get_basic_metrics(self):
        """ Return a dictionnary with basic metrics.
        """
        basic_stats = dict(
            total_read=self.total_read,
            total_base=self.total_base,
            mean_length=self.mean_length,
            q20=self.q20,
            gc_content=self.gc_content
        )
        return basic_stats
