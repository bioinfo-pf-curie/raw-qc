"""Add search patterns and config options for the things that are used in
Autotropos-MultiQC.
"""
from __future__ import absolute_import
from multiqc import config


def multiqc_rawqc_config():
    """ Set up MultiQC config defaults for this package """
    rawqc_search_patterns = {
        "rawqc_metrics": {
            "fn": "*_basicmet.json",
        },
        "rawqc_trimming": {
            "fn": "*.trim.json",
        }
    }
    config.update_dict(config.sp, rawqc_search_patterns)
