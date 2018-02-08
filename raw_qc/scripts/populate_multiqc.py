#!/usr/bin/env python
# coding: utf-8
#
#  This file is part of Raw-QC software.
#
#  Copyright (c) 2017 - Institut Curie
#
#  File author(s):
#      Dimitri Desvillechabrol <dimitri.desvillechabrol@curie.fr>,
#
#  Distributed under the terms of the CeCILL-B license.
#  The full license is in the LICENSE file, distributed with this software.
#
##############################################################################
import os
from collections import OrderedDict

import click

from raw_qc.utils import get_package_location


@click.command(
    context_settings={'help_option_names': ['-h', '--help']}
)
@click.option(
    '-i', '--input', 'metadata',
    type=click.Path(exists=True),
    nargs=1,
    metavar="<RIMS metadata file>",
    default=None,
    help="Information file generate by RIMS."
)
@click.option(
    '-o', '--output',
    type=click.Path(),
    metavar='OUTPUT',
    nargs=1,
    default=None,
    help="Write the config file populate with the RIMS metadata file."
         "(multiqc_config.yaml)"
)
def main(metadata, output):
    # get multiqc config
    rawqc_dir = os.sep.join([get_package_location('raw_qc'), 'raw_qc'])
    yaml_conf = os.sep.join([rawqc_dir, 'config', 'multiqc_config.yaml'])
    multiqc_list = ["custom_logo: '{}'".format(os.sep.join([
        rawqc_dir, 'resources', 'images', 'institut_curie.jpg'
    ]))]
    multiqc_list += ["report_header_info:"]

    if metadata is not None:
        # create rims dict
        rims_dict = OrderedDict([
            ('data', 'Date'),
            ('demand_code', "RIMS code"),
            ('project_name', "Project name"),
            ('ngs_contact', "Contact E-mail"),
            ('technical_contact', "Main contact"),
            ('team_leader|unit', "Team leader"),
            ('biological_application', "Application type"),
            ('sequencer', "Sequencing setup"),
            ('runs', 'Runs')
        ])
        # get data from metadata
        metadict = dict()
        with open(metadata, 'r') as fp:
            for line in fp:
                row = line.split('\t')
                metadict[row[0]] = row[1].strip()
        # add ngs mail if no agent was set
        if 'ngs_contact' not in metadict:
            metadict['ngs_contact'] = 'ngs.lab@curie.fr'
        multiqc_list += [
            "    - {}: '{}'".format(value, metadict[key])
            for key, value in rims_dict.items() if key in metadict
        ]
    else:
        multiqc_list += ["  - Contact E-mail: 'ngs.lab@curie.fr'"]

    # get config file
    with open(yaml_conf, 'r') as file_content:
        conf_string = file_content.read()
    custom_content = '\n'.join(multiqc_list)
    
    # write file
    if output is None:
        output = 'multiqc_config.yaml'
    with open(output, 'w') as fp:
        print(conf_string.format(**{'custom_content': custom_content}),
              file=fp)
