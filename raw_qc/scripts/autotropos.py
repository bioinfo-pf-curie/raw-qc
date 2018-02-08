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
""" Autotropos: A wrapper of Atropos to trim adapters with automatic detection
of adapters.
"""
import json
import os
from collections import OrderedDict

import click

from raw_qc import Atropos
from raw_qc import logger


@click.command(
    context_settings={'help_option_names': ['-h', '--help']}
)
@click.option(
    '-1', '--read1',
    type=click.Path(exists=True),
    metavar='FILE1',
    nargs=1,
    required=True,
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
    '-o', '--output',
    type=click.Path(),
    metavar='OUT_FILE1',
    nargs=1,
    default=None,
    help="Write trimmed reads to FASTQ FILE. The summary report is "
         "sent to standard output. (write to standard output)"
)
@click.option(
    '-p', '--paired-output', 'paired_output',
    type=click.Path(),
    metavar='OUT_FILE2',
    nargs=1,
    default=None,
    help="Write second read in a pair to FASTQ FILE."
)
@click.option(
    '-a', '--three-prime-adapter-r1', 'adapt_3p_r1',
    type=str,
    metavar='ADAPTER',
    nargs=1,
    default=None,
    help="Sequence of an adapter ligated to the 3' end (paired "
         "data: of the first read). The adapter and subsequent "
         "bases are trimmed. If a '$' character is appended "
         "('anchoring'), the adapter is only found if it is a "
         "suffix of the read."
)
@click.option(
    '-A', '--three-prime-adapter-r2', 'adapt_3p_r2',
    type=str,
    metavar='ADAPTER',
    nargs=1,
    default=None,
    help="Sequence of an adapter ligated to the 3' end of the "
         "second read in a pair."
)
@click.option(
    '-g', '--five-prime-adapter-r1', 'adapt_5p_r1',
    type=str,
    metavar='ADAPTER',
    nargs=1,
    default=None,
    help="Sequence of an adapter ligated to the 5' end (paired "
         "data: of the first read). The adapter and any "
         "preceding bases are trimmed. Partial matches at the 5' "
         "end are allowed. If a '^' character is prepended "
         "('anchoring'), the adapter is only found if it is a "
         "prefix of the read. (none)"
)
@click.option(
    '-G', '--five-prime-adapter-r2', 'adapt_5p_r2',
    type=str,
    metavar='ADAPTER',
    nargs=1,
    default=None,
    help="Sequence of an adapter ligated to the 5' end of the "
         "second read in a pair."
)
@click.option(
    '-b', '--both-prime-adapter-r1', 'adapt_bp_r1',
    type=str,
    metavar='ADAPTER',
    nargs=1,
    default=None,
    help="Sequence of an adapter that may be ligated to the 5' "
         "or 3' end (paired data: of the first read). Both types "
         "of matches as described under -a und -g are allowed. "
         "If the first base of the read is part of the match, "
         "the behavior is as with -g, otherwise as with -a. This "
         "option is mostly for rescuing failed library "
         "preparations - do not use if you know which end your "
         "adapter was ligated to! (none)"
)
@click.option(
    '-B', '--both-prime-adapter-r2', 'adapt_bp_r2',
    type=str,
    metavar='ADAPTER',
    nargs=1,
    default=None,
    help="5'/3 adapter to be removed from second read in a pair.(no)"
)
@click.option(
    '-m', '--minimum-length', 'mlength',
    type=int,
    metavar='LENGTH',
    nargs=1,
    default=0,
    help="Discard trimmed reads that are shorter than LENGTH. "
         "Reads that are too short even before adapter removal "
         "are also discarded. In colorspace, an initial primer "
         "is not counted. (0)"
)
@click.option(
    '-n', '--times',
    metavar='COUNT',
    nargs=1,
    default=1,
    help="Remove up to COUNT adapters from each read. (1)"
)
@click.option(
    '-O', '--overlap',
    type=int,
    metavar='MINLENGTH',
    nargs=1,
    default=3,
    help="If the overlap between the read and the adapter is "
         "shorter than MINLENGTH, the read is not modified. "
         "Reduces the no. of bases trimmed due to random adapter "
         "matches. (3)"
)
@click.option(
    '--auto', 'auto_detect',
    is_flag=True,
    help="Adapters are detected and then removed with Atropos. "
         "For instance, it detects only 3' end adapters."
)
@click.option(
    '--amplicon',
    is_flag=True,
    help="Atropos warns about incomplete adapter sequences. "
         "Autotropos cut remaining base and rerun Atropos with the "
         "missing base."
         "If your DNA fragments are not random, such as in amplicon "
         "sequencing, then this is to be expected and the warning "
         "can be ignored."
)
@click.option(
    '--nb-pass', 'nb_pass',
    type=int,
    metavar='MAXINT',
    nargs=1,
    default=3,
    help="Maximum number of passage if Atropos detect other known "
         "sequence. This option is used with --auto option."
)
@click.option(
    '-t', '--threads',
    type=int,
    metavar='INT',
    default=2,
    help="Number of threads to use for read trimming. Set to 0 "
         "to use max available threads. (Do not use "
         "multithreading)"
)
@click.option(
    '-l', '--logs', 'logfile',
    type=click.Path(),
    metavar='FILE',
    default=None,
    help="Log file for Atropos."
)
@click.option(
    '-j', '--json', 'jsonfile',
    type=click.Path(),
    metavar='JSON',
    default=None,
    help="JSON file with basic metrics of trimming. Usable with "
         "fastq_basic_metrics"
)
@click.option(
    '--debug',
    is_flag=True,
    help="Debug mode if you have any problem"
)
def main(read1, read2, output, paired_output, adapt_3p_r1, adapt_3p_r2,
         adapt_5p_r1, adapt_5p_r2, adapt_bp_r1, adapt_bp_r2, mlength,
         times, overlap, auto_detect, amplicon, nb_pass, threads, logfile,
         jsonfile, debug):
    """ Autotropos is a wrapper of Atropos to trim adapters with automatic
    detection of adapters.

    If you set --auto option, It searches which adapters are in the sample and
    remove them.
    """
    if debug:
        logger.setLevel('DEBUG')

    # Init atropos class
    atrps = Atropos(
        read1=read1,
        read2=read2,
        logfile=logfile
    )
    # Set adapters
    atrps.adapters = {
        "-a": adapt_3p_r1,
        "-A": adapt_3p_r2,
        "-g": adapt_5p_r1,
        "-G": adapt_5p_r2,
        "-b": adapt_bp_r1,
        "-B": adapt_bp_r2
    }

    # Check if at least one adapter is set
    adapt_flag = False
    for o, adapter in atrps.adapters.items():
        if adapter is not None:
            adapt_flag = True
    if not adapt_flag and not auto_detect:
        logger.error("You do not set any adapters or the --auto option.")
        raise click.BadOptionUsage(
            "-a or --auto options are missing."
        )

    # Set options for atropos
    options = "--times {} --overlap {} --minimum-length {} --quiet".format(
        times,
        overlap,
        mlength
    )

    # Run atropos trim
    if not auto_detect:
        logger.info("Run the trimming with requested adapters...")
        atrps.remove_adapters(
            output_r1=output,
            output_r2=paired_output,
            options=options,
            threads=threads,
            amplicon=amplicon
        )
        if jsonfile is not None:
            atrps.write_stats_json(jsonfile)
        logger.info("Autotropos finished !")
        return

    # Detect adapters
    logger.info("Run the trimming with adapters auto-detections")
    logger.info("Try to detect adapters...")
    detected_ad = atrps.guess_adapters()
    dict_adapt = OrderedDict({'-a': None, '-A': None})
    for i, (opt, read) in enumerate(zip(dict_adapt.keys(), detected_ad)):
        if read is not None:
            dict_adapt[opt] = read['known_sequence']
            logger.info(
                "An adapter is detected at the 3' end of reads {}:\n"
                "{}".format(
                    i + 1,
                    "\n".join(
                        "   - {}: {}".format(k, v) for k, v in read.items()
                    )
                )
            )
        else:
            # at the moment, if only one option is found we do not trim
            logger.info("Nothing to trim, symlinks are generated.")
            create_symlink(read1, output)
            if read2 is not None:
                create_symlink(read2, paired_output)
            if jsonfile is not None:
                trim_dict = {
                    'mean_read_length': atrps.detection['derived']['mean_sequence_lengths'][0],
                    'percent_trim': 0.0,
                    'percent_discard': 0.0
                }
                with open(jsonfile, 'w') as fp:
                    json.dump(trim_dict, fp)
            logger.info("Autotropos finished !")
            return

    # Run atropos trim with known adapters
    logger.info("Run the trimming with detected adapters...")
    atrps.adapters = dict_adapt
    atrps.remove_adapters(
        output_r1=output,
        output_r2=paired_output,
        options=options,
        threads=threads,
        amplicon=amplicon
    )

    logger.info("Try to re-detect adapters...")
    trimmed = Atropos(
        read1=output,
        read2=paired_output,
    )
    # otherwise the logfile will be removed
    trimmed._logfile = logfile
    redetect = trimmed.guess_adapters()
    detect_flag = False
    for i, (opt, first, second) in enumerate(zip(dict_adapt.keys(),
                                                 detected_ad, redetect)):
        if second is not None:
            if first['known_sequence'] == second['known_sequence']:
                logger.info("Adapters are not properly removed, the trimming "
                            "will be done with the longest kmer.")
                dict_adapt[opt] = first['longest_kmer']
                detect_flag = True
            else:
                logger.info(
                    "Another sequence is detected at the 3' end of R{}:\n"
                    "{}".format(
                        i, "\n".join("   - {}: {}".format(k, v)
                                     for k, v in second.items())
                    )
                )
        else:
            logger.info("Adapters for R{} are perfectly trimmed. No known "
                        "sequence detected.".format(i + 1))

    # Rerun atropos trim with longest kmer
    if detect_flag:
        logger.info("Run the trimming with detected longest kmer...")
        atrps.adapters = dict_adapt
        atrps.remove_adapters(
            output_r1=output,
            output_r2=paired_output,
            options=options,
            threads=threads,
            amplicon=amplicon
        )
    if jsonfile is not None:
        atrps.write_stats_json(jsonfile)
    logger.info("Autotropos finished !")


def create_symlink(source, link_name):
    try:
        os.remove(link_name)
    except FileNotFoundError:
        pass
    os.symlink(os.path.realpath(source), link_name)
