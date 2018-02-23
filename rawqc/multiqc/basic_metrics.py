#!/usr/bin/env python3
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
""" MultiQC module to parse JSON file generated by `fastq_basic_metrics`
"""
from collections import OrderedDict
import json

from multiqc.modules.base_module import BaseMultiqcModule
from multiqc.plots import table
from multiqc import config


class MultiqcModule(BaseMultiqcModule):
    """ Basic metrics module.
    """
    def __init__(self):
        # Initialise the parent object
        super(MultiqcModule, self).__init__(
            name='Basic Metrics',
            anchor='basic_metrics',
            href='https://gitlab.curie.fr/ddesvill/autotropos',
            info="Calculated basic metric for the raw-qc pipeline."
        )

        # Find and load basic metrics
        self.basicmet_data = dict()
        self.total_cluster = 0
        for f in self.find_log_files('basic_metrics'):
            self.parse_basicmet_log(f)
        # MultiQC seems to add empty table if there are no data
        if self.basicmet_data:
            try:
                config.report_header_info.append({
                    "Total number of clusters": '{:,.0f}'.format(
                        self.total_cluster).replace(',',' ')
                })
            except AttributeError:
                pass
            for k, v in self.basicmet_data.items():
                v['sample_representation'] = (v['nb_cluster']
                    / self.total_cluster) * 100
            self.add_section(plot=self.basic_metrics_table())

    def parse_basicmet_log(self, f):
        """ Parse the json file with json python library.
        """
        data = json.loads(f['f'])
        if 'basic_metrics' in data:
            self.total_cluster += data['nb_cluster']
            self.basicmet_data[data['ID']] = data

    def basic_metrics_table(self):
        """ Take the parsed stats from fastq basic metrics and create a basic
        table with interesting information.
        """
        headers = OrderedDict()
        headers['sample_name'] = {
            'namespace': 'Rawqc_basic_metrics',
            'title': "Biological name",
            'description': "Biological identifier",
            'format': None,
            'scale': None
        }
        headers['total_read'] = {
            'namespace': 'Rawqc_basic_metrics',
            'title': "Total reads",
            'description': "Total number of read",
            'min': 0,
            'format': '{:,.0f}',
            'scale': 'YlGn'
        }
        headers['sample_representation'] = {
            'namespace': 'Rawqc_basic_metrics',
            'title': 'Sample representation',
            'description': 'Percentage of cluster',
            'suffix': '%',
            'scale': 'RdYlGn'
        }
        headers['mean_length'] = {
            'namespace': 'Rawqc_basic_metrics',
            'title': 'Mean length',
            'description': 'Read mean length',
            'suffix': ' bp',
            'scale': 'YlGn'
        }
        headers['total_base'] = {
            'namespace': 'Rawqc_basic_metrics',
            'title': 'Total bases',
            'description': 'Total number of base',
            'suffix': ' bp',
            'format': '{:,.0f}',
            'scale': 'YlGn'
        }
        headers['R1-Q20'] = {
            'namespace': 'Rawqc_basic_metrics',
            'title': 'Q20 of R1',
            'description': 'Number of base > Q20 / Total of base',
            'max': 100,
            'min': 0,
            'suffix': '%',
            'scale': 'RdYlGn'
        }
        if next(iter(self.basicmet_data.values()))['R2-Q20'] != 'None':
            headers['R2-Q20'] = {
                'namespace': 'Rawqc_basic_metrics',
                'title': 'Q20 of R2',
                'description': 'Number of base > Q20 / Total of base',
                'max': 100,
                'min': 0,
                'suffix': '%',
                'scale': 'RdYlGn'
            }
        headers['mean_read_length'] = {
            'namespace': 'Atropos',
            'title': 'Trimmed mean length',
            'description': 'Read mean length after trimming',
            'scale': 'YlGn'
        }
        headers['percent_trim'] = {
            'namespace': 'Atropos',
            'title': 'Trimmed reads',
            'description': 'Trimmed reads percentage',
            'max': 100,
            'min': 0,
            'suffix': '%',
            'scale': 'YlGn'
        }
        headers['percent_discard'] = {
            'namespace': 'Atropos',
            'title': 'Discarded reads',
            'description': 'Discarded reads percentage',
            'max': 100,
            'min': 0,
            'suffix': '%',
            'scale': 'YlGn'
        }
        config = {
            'id': 'basic_metrics_table',
            'table_title': 'Basic Metrics',
            'save_file': True
        }
        return table.plot(self.basicmet_data, headers, config)
