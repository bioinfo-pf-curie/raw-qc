"""Add search patterns and config options for the things that are used in
Autotropos-MultiQC.
"""
from __future__ import absolute_import
from multiqc import config


def multiqc_autotropos_config():
    """ Set up MultiQC config defaults for this package """
    autotropos_search_patterns = {
        'basic_metrics': {
            'fn': '*_basicmet.json',
        },
    }
    config.update_dict(config.sp, autotropos_search_patterns)
