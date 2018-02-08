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
""" A wrapper python to run bash executable."""
import os

import click
import pexpect

from raw_qc import logger
from raw_qc.utils import get_package_location, copy_file
RAWQC = os.sep.join([get_package_location('raw_qc'), 'raw_qc'])


def get_config_file(ctx, param, value):
    if not value or ctx.resilient_parsing:
        return
    src = os.sep.join([RAWQC, 'config', 'rawqc_config.json'])
    dst = os.sep.join([os.getcwd(), 'rawqc_config.json'])
    flag = True
    if os.path.exists(dst):
        flag = False
        chance = 3
        yes = {'yes', 'y', 'true', 't', '1'}
        nop = {'no', 'nop', 'n', 'false', 'f', 0}
        while chance > 0:
            chance -= 1
            answer = input("The file rawqc_config.json already exist. "
                           "Do you want to overwrite it? ")
            answer = answer.lower()
            if answer in nop:
                flag = False
                break
            elif answer in yes:
                flag = True
                break
            else:
                logger.info("Incorrect answer.")
    if flag:
        copy_file(src, dst)
        logger.info("The rawqc_config.json file is copied.")
    else:
        logger.info("Config file is not copied.")
    ctx.exit()

@click.command(
    context_settings={'help_option_names': ['-h', '--help']}
)
@click.option(
    '-c', '--config-file', 'config',
    type=click.Path(exists=True),
    metavar='JSON',
    required=True,
    help="The JSON config file of the pipeline."
)
@click.option(
    '-o', '--output-dir', 'outdir',
    type=click.Path(),
    metavar='OUTDIR',
    default='.',
    help="The directory where all the analysis are done"
)
@click.option(
    '-s', '--sample-plan', 'sample_plan',
    type=click.Path(exists=True),
    metavar='FILE',
    default=None,
    help="Sample plan with all sample to run in cloud. NAMESPACE is the "
         "namespace you want to use for parallele. [required if no --read1]"
)
@click.option(
    '--get-config',
    is_flag=True,
    callback=get_config_file,
    expose_value=False,
    is_eager=True,
    help="Copy the JSON config file for the pipeline."
)
@click.option(
    '--cluster',
    is_flag=True,
    help="Run the pipeline on a cluster with Torque as scheduler."
)
@click.option(
    '-1', '--read1',
    type=click.Path(exists=True),
    metavar='FILE1',
    default=None,
    nargs=1,
    help="The first read fastq file (R1) or a single-end read file."
)
@click.option(
    '-2', '--read2',
    type=click.Path(exists=True),
    metavar='FILE2',
    nargs=1,
    default=None,
    help="The second read fastq file (R2)."
)
@click.option(
    '-p', '--prefix',
    type=str,
    metavar='STRING',
    default=None,
    help="Prefix name of output files. "
         "(ie OUTDIR/PREFIX/task/PREFIX.extension)"
)
@click.option(
    '-w', '--latency-wait', 'latency',
    type=float,
    metavar='SECONDS',
    default=None,
    help="Wait SECONDS between each cluster submission"
)
@click.option(
    '--debug',
    is_flag=True,
    help="Debug mode if you have any problem"
)
def main(config, outdir, sample_plan, cluster, read1, read2, prefix, latency,
         debug):
    cmd = [os.sep.join([RAWQC, 'pipeline', 'raw-qc']), '-c', config, '-o', outdir]
    if sample_plan:
        cmd += ['-s', sample_plan]
    elif read1:
        cmd += ['-1', read1]
        if read2:
            cmd += ['-2', read2]
        if prefix:
            cmd += ['-p', prefix]
    else:
        logger.error('Missing input')
        raise FileNotFoundError
    if cluster:
        cmd += ['--cluster']
    if debug:
        cmd += ['--debug']
    if latency:
        cmd += ['-w', latency]
    logger.info("Raw-QC is launching your jobs.")
    pexpect.run(" ".join(cmd), timeout=None)
    logger.info("Your jobs are running !")
