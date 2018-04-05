# coding: utf-8

""" rawqc_atropos: A wrapper of Atropos to trim adapters with automatic
detection of adapters.
"""

import json
import os
import shutil
import subprocess as sp
import tempfile
import uuid
from collections import OrderedDict

import click

from rawqc import Atropos
from rawqc import logger


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
    '-s', '--sub-size', 'sub_size',
    type=int,
    metavar='SIZE',
    nargs=1,
    default=500000,
    help="The sub-sample size to detect adapters.(500 000 reads)"
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
    '--algorithm', 'algorithm',
    type=click.Choice(['known', 'heuristic']),
    default=None,
    help="Which detector to use. Heuristic is the most sensible but have a "
         "quadratic complexity and becomes too slow/memory-intensive when your"
         " reads are taller than 150bp.(automatically chosen)"
)
@click.option(
    '--amplicon',
    is_flag=True,
    help="Atropos warns about incomplete adapter sequences. "
         "Rawqc_atropos cut remaining base and rerun Atropos with the "
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
    help="JSON prefix file with basic metrics of trimming. Usable with"
         " fastq_basic_metrics and MultiQC"
)
@click.option(
    '--temp-dir', 'tmp',
    type=click.Path(),
    metavar='TMPDIR',
    default=tempfile.gettempdir(),
    help="Temporary directory where are write temporary files for the "
         "auto-detection of adapters.(TMPDIR/tmp_rawqc_atrps)"
)
@click.option(
    '--debug',
    is_flag=True,
    help="Debug mode if you have any problem"
)
def main(read1, read2, output, paired_output, adapt_3p_r1, adapt_3p_r2,
         adapt_5p_r1, adapt_5p_r2, adapt_bp_r1, adapt_bp_r2, sub_size, mlength,
         times, overlap, auto_detect, algorithm, amplicon, nb_pass, threads,
         logfile, jsonfile, tmp, debug):
    """ Rawqc_atropos is a wrapper of Atropos to trim adapters with automatic
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
        logger.info("Rawqc_atropos finished !")
        return

    # Detect adapters
    logger.info("Run the trimming with adapters auto-detections")

    # Create subsample with seqtk in temporary directory
    tmp = os.path.abspath(tmp.rstrip('/')) + os.sep + 'rawqc_atropos_' \
        + uuid.uuid4().hex
    os.mkdir(tmp)
    logger.info("Create subsamples of {} reads in {}...".format(sub_size, tmp))
    tmp_r1 = tmp + os.sep + uuid.uuid4().hex + '.fastq'
    seqtk = "seqtk sample -s100 {} {}"
    with open(tmp_r1, "w") as fout:
        seqtk_proc = sp.Popen(seqtk.format(read1, sub_size).split(),
                              stdout=fout)
        seqtk_proc.communicate()
    if read2:
        tmp_r2 = tmp + os.sep + uuid.uuid4().hex + '.fastq'
        with open(tmp_r2, "w") as fout:
            seqtk_proc = sp.Popen(seqtk.format(read2, sub_size).split(),
                                  stdout=fout)
            seqtk_proc.communicate()
    else:
        tmp_r2 = None

    # Set detection algorithm
    auto_algo = True if algorithm is None else False
    if algorithm == "heuristic":
        max_read = 20000
    else:
        algorithm = "known"
        max_read = 50000

    # Detect adapters in the subsample
    logger.info("Try to detect adapters...")
    tmp_atrps = Atropos(tmp_r1, tmp_r2)
    tmp_atrps.adapters = atrps.adapters
    if logfile:
        tmp_atrps._logfile = logfile

    detected_ad = tmp_atrps.guess_adapters(algorithm=algorithm,
                                           max_read=max_read)
    dict_adapt = OrderedDict({'-a': None, '-A': None})
    for i, (opt, read) in enumerate(zip(dict_adapt.keys(), detected_ad)):
        if read is not None:
            dict_adapt[opt] = read['sequence']
            logger.info(
                "An adapter is detected at the 3' end of reads {}:\n"
                "{}".format(
                    i + 1,
                    "\n".join(
                        "   - {}: {}".format(k, v) for k, v in read.items()
                        if k != 'read'
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
                atrps.write_stats_json(jsonfile)
            logger.info("Rawqc_atropos finished !")
            return

    # Run atropos trim with known adapters
    logger.info("Run the trimming with detected adapters...")

    # Some times atropos did a better job with reverse complement adapters
    tmp_r1_out = tmp + os.sep + uuid.uuid4().hex + '.fastq'
    tmp_r2_out = tmp + os.sep + uuid.uuid4().hex + '.fastq' if read2 else None

    # Trim with detected adapters
    normal_trim = tmp_atrps.remove_adapters(
        output_r1=tmp_r1_out,
        output_r2=tmp_r2_out,
        options=options,
        threads=threads,
        amplicon=amplicon
    )

    # Lets trim with reverse complement adapters
    trans_tab = str.maketrans('ACGT', 'TGCA')
    tmp_atrps.adapters = {
        key: value.translate(trans_tab)[::-1]
        for key, value in dict_adapt.items() if value is not None
    }
    reverse_trim = tmp_atrps.remove_adapters(
        output_r1=tmp_r1_out,
        output_r2=tmp_r2_out,
        options=options,
        threads=threads,
        amplicon=amplicon
    )
    iter_trim = zip(dict_adapt.keys(), normal_trim.items(),
                    reverse_trim.items())
    for opt, normal, reverse in iter_trim:
        dict_adapt[opt] = normal[0] if normal[1] > reverse[1] else reverse[0]

    # Test with the best orientation
    tmp_atrps.adapters = dict_adapt
    tmp_atrps.remove_adapters(
        output_r1=tmp_r1_out,
        output_r2=tmp_r2_out,
        options=options,
        threads=threads,
        amplicon=amplicon
    )

    logger.info("Try to re-detect adapters...")
    trimmed = Atropos(
        read1=tmp_r1_out,
        read2=tmp_r2_out
    )
    # Otherwise the logfile will be removed
    if logfile:
        trimmed._logfile = logfile

    # Check if adapters are corectly removed
    redetect = trimmed.guess_adapters(algorithm=algorithm, max_read=max_read)
    detect_flag = False
    for i, (opt, first, second) in enumerate(zip(dict_adapt.keys(),
                                                 detected_ad, redetect)):
        if second is not None:
            if first['sequence'] == second['sequence']:
                logger.warning("Adapters are not properly removed at the 3' "
                               "end of R{}.".format(i + 1))
                dict_adapt[opt] = first['longest_kmer']
                detect_flag = True
            else:
                logger.warning(
                    "Another sequence is detected at the 3' end of R{}:\n"
                    "{}".format(
                        i, "\n".join("   - {}: {}".format(k, v)
                                     for k, v in second.items() if k != 'read')
                    )
                )
        else:
            logger.info("Adapters for R{} are perfectly trimmed. No known "
                        "sequence detected.".format(i + 1))

    if auto_algo:
        from atropos.io.seqio import FastqReader
        with FastqReader(tmp_r1) as filin:
            read = next(iter(filin))
            read_length = len(read)
            algorithm = 'heuristic' if 49 < read_length < 152 else 'known'
            max_read = 50000 if algorithm == 'known' else 20000

    # Rerun atropos trim with longest kmer heuristic algorithm
    if detect_flag and algorithm == 'heuristic':
        detected_ad = tmp_atrps.guess_adapters(algorithm=algorithm,
                                               max_read=max_read)
        logger.info("Run the trimming with detected longest kmer...")
        try:
            tmp_atrps.adapters = {
                opt: adapter['longest_kmer']
                for opt, adapter in zip(dict_adapt.keys(), detected_ad)
            }
            tmp_atrps.remove_adapters(
                output_r1=tmp_r1_out,
                output_r2=tmp_r2_out,
                options=options,
                threads=threads,
                amplicon=amplicon
            )
        except TypeError:
            pass

    logger.info("Clean the tmp dir.")
    shutil.rmtree(tmp)

    logger.info("Run trimming on the file.")
    atrps.adapters = tmp_atrps.adapters
    atrps.remove_adapters(
        output_r1=output,
        output_r2=paired_output,
        options=options,
        threads=threads,
        amplicon=amplicon
    )
    if jsonfile is not None:
        atrps.write_stats_json(jsonfile)
    logger.info("Rawqc_atropos finished !")


def create_symlink(source, link_name):
    try:
        os.remove(link_name)
    except FileNotFoundError:
        pass
    os.symlink(os.path.realpath(source), link_name)
