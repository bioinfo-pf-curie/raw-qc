# coding: utf-8
#
#  This file is part of rawqc software.
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
""" Atropos is a NGS read trimming tool that is specific, sensitive and speedy.
This is a python wrapper to ease usage with detection tool.
"""
import os
import sys

from atropos.commands import COMMANDS
from rawqc import logger

__all__ = ['Atropos']


class Atropos(object):
    """ Python wrapper of Atropos.
    """
    def __init__(self, read1, read2=None, logfile=None):
        """.. rubric:: contructor

        :param str read1: FastQ filename of the R1 or single-ends.
        :param str read2: FastQ filename of the R2. (optional)
        :param str logfile: log filename for atropos logs.
        """
        self._r1 = read1
        self._r2 = read2
        self.logfile = logfile
        self._adapters = {
            '-a': None, '-A': None,
            '-g': None, '-G': None,
            '-b': None, '-B': None
        }
        self._detection = None
        self._trimming = None

    @property
    def r1(self):
        """ Get the filename of R1.
        """
        return self._r1

    @property
    def r2(self):
        """ Get the filename of R2.
        """
        return self._r2

    @property
    def adapters(self):
        """ Get or set adapters to remove in R1 and R2 FASTQ files.
        The getter return a dictionnary with an adapter associated with an
        option. Links are presented in this table:

            =========================     ============================
            Adapter type                  Command-line option
            =========================     ============================
            3’ adapter                    `-a/-A ADAPTER`
            5’ adapter                    `-g/-G ADAPTER`
            5’ or 3’ (both possible)      `-b/-B ADAPTER`
            Linked adapter 	          `-a/-A ADAPTER1...ADAPTER2`
            =========================     ============================

        The setter take a dictionnary and update the adapters dictionnary.
        """
        return self._adapters.copy()

    @adapters.setter
    def adapters(self, adapter_dict):
        try:
            for key in adapter_dict:
                if key in self._adapters.keys():
                    self._adapters[key] = adapter_dict[key]
        except TypeError:
            logger.error("The adapters can only be set with a dictionary")
            sys.exit(1)

    @property
    def logfile(self):
        """ Get and set the log file. If the log file exists, the setter will
        remove it.
        """
        return self._logfile

    @logfile.setter
    def logfile(self, filename):
        try:
            os.remove(filename)
            self._logfile = filename
        except FileNotFoundError:
            self._logfile = filename
        except IsADirectoryError:
            logger.error("The log filename already exists as a directory.")
            sys.exit(21)
        except TypeError:
            self._logfile = "/dev/null"

    @property
    def detection(self):
        """ Get the atropos detection summary. This variable is set when
        :meth:`Atropos.guess_adapters` is used.
        """
        return self._detection

    @property
    def trimming(self):
        """ Get the atropos trimming summary. This variable is set when
        :meth:`Atropos.remove_adapters` is used.
        """
        return self._trimming

    def remove_adapters(self, output_r1, output_r2=None, options='',
                        threads=2, amplicon=False, iteration=5):
        """ Method that wrap trim option of Atropos.

        :param str output_r1: FastQ filename of trimmed R1.
        :param str output_r2: FastQ filename of trimmed R2.
        :param str options: options compatible with atropos trim.
        :param int threads: number of threads.
        :param bool amplicon: if data is amplicon then rawqc_atropos will not
                              iterate on missing bases.
        :param int iteration: number of iteration if rawqc_atropos detect a
                              missing base in an adapter.
        """
        # Create the command line
        cmd = ['--threads', str(threads)]
        if not self.logfile.startswith('/dev/null'):
            cmd += ['--log-file', self.logfile]
        if options:
            cmd += options.split()
        if self.r2:
            cmd += ['--aligner', 'insert', '-pe1', self.r1, '-pe2', self.r2,
                    '-o', output_r1, '-p', output_r2]
            adapt_opt = ('-a', '-A', '-g', '-G', '-b', '-B')
        else:
            cmd += ['-se', self.r1, '-o', output_r1]
            adapt_opt = ('-a', '-g', '-b')
        cmd += ["{0} {1}".format(key, self._adapters[key])
                for key in adapt_opt if self._adapters[key]]
        logger.debug(
            "Atropos trim is run with this command line:\n"
            "atropos {}".format(" ".join(cmd))
        )

        # Run atropos trim
        trimming = COMMANDS['trim']
        retcode, summary = trimming.execute(cmd)

        # Commands run seems to fail seldomly on the cluster of the Curie
        # Institute. Maybe because some nodes are slower than others
        if retcode > 0:
            import time

            time.sleep(5)
            retcode, summary = trimming.execute(cmd)
            if retcode > 0:
                logger.error(retcode)
                logger.error("Atropos trim did not work.")
                sys.exit(retcode)

        warned = False
        map_type = {
            "regular 3'": ['-a', '-A'],
            "variable 5'/3'": ['-b', '-B'],
            "regular 5'": ['-g', '-G']
        }
        # dict contain only one value that have multiple key depending of
        # alignment type
        trimmed = next(iter(summary['trim']['modifiers'].values()))
        for r, adapters in enumerate(trimmed['adapters']):
            for k, adapter in adapters.items():
                # Check if no base is missing
                adj_base = adapter['adjacent_bases']
                total = sum(adj_base.values())
                for base, number in adj_base.items():
                    # if adj_base is '', do nothing
                    if not base:
                        continue
                    ratio = number / total
                    # If base missing
                    if total > 20 and ratio >= 0.8:
                        opt = map_type[adapter['where']['desc']][r]
                        logger.warning(
                            "A '{}' is missing in the adapter sequence of "
                            "option '{}'.".format(base, opt)
                        )
                        if not amplicon:
                            warned = True
                            self._adapters[opt] = base + adapter['sequence']
                            logger.info(
                                "New adapters for option {} is {}".format(
                                    opt,
                                    self._adapters[opt]
                                )
                            )

        # if warned the adapter removal is rerun
        if warned and iteration > 0:
            logger.info("Rerun adapter removal with new adapters.")
            iteration -= 1
            return self.remove_adapters(output_r1, output_r2, options,
                                        threads, amplicon, iteration)
        self._trimming = summary

    def guess_adapters(self, adapter_file=None, default_contaminant=True,
                       algorithm='heuristic', kmer_size=12, max_read=25000):
        """ Method that wrap adapter detection of Atropos. The method uses
        a FASTA file that contains adapters sequence and Atropos will guess the
        correct adapter among the rest. If no file is requested, Atropos uses
        by default a curated list of commonly used adapter sequences.

        atropos detect -pe1 read1.fq -pe2 read2.fq

        This method detects only adapter located at the 3' position.

        :param str adapter_file: FASTA file name with adapter sequences.
        :param bool default_contaminant: Use the default contaminant file from
                                         atropos.
        :param int max_read: Number of reads uses for the adapter detection.

        More information:
            - http://atropos.readthedocs.io/en/latest/guide.html#adapter-detection
        """
        # Create the command link_name
        cmd = ['--quiet', '--max-read', str(max_read), '--detector', algorithm,
               '--kmer-size', str(kmer_size)]
        if not self.logfile.startswith('/dev/null'):
            cmd += ['--log-file', self.logfile]
        if self.r2:
            cmd += ['-pe1', self.r1, '-pe2', self.r2]
        else:
            cmd += ['-se', self.r1]
        if adapter_file:
            cmd += ['-F', adapter_file]
        if not default_contaminant:
            cmd += ['--no-default-contaminants']

        logger.debug(
            "Atropos detection is run with this command line:\n"
            "atropos detect {}".format(" ".join(cmd))
        )

        # Run atropos detect command
        with open(self.logfile, 'a') as fp:
            orig_stdout = sys.stdout
            sys.stdout = fp
            detection = COMMANDS['detect']
            retcode, summary = detection.execute(cmd)

            # Commands run seems to fail seldomly on the cluster of Curie
            # Institute. Maybe because some nodes are slower than other
            if retcode > 0:
                import time

                time.sleep(5)
                retcode, summary = detection.execute(cmd)
                if retcode > 0:
                    logger.error("Atropos detection did not work:")
                    sys.exit(retcode)
            sys.stdout = orig_stdout

        # Get detect summary information
        detected = summary['detect']
        detect_list = [
            {
                'read': i,
                'adapters_names': hit['known_names'][0],
                'known_sequence': hit['known_seqs'][0],
                'longest_kmer': hit['longest_kmer']
            } if hit['is_known'] else None
            for i, data in enumerate(detected['matches']) for hit in data
        ]

        adapter_list = [None, None]
        if self.r2 is None:
            adapter_list = [None]

        for adapter in detect_list:
            try:
                if adapter_list[adapter['read']] is None:
                    adapter_list[adapter['read']] = adapter
            except TypeError:
                pass
        self._detection = summary
        return adapter_list

    def write_stats_json(self, filename):
        """ Write json stats file of rawqc_atropos.
        This file is read by MultiQC to summarize results of the trimming.
        Use :meth:`Atropos.guess_adapters` to have information about adapters
        detection and :meth:`Atropos.remove_adapters` for adapters removal.

        :param str filename: output JSON file name.
        """
        import json

        # get values
        stats_dict = dict()
        if self.trimming is not None:
            trimmed = next(iter(self.trimming['trim']['modifiers'].values()))
            n = 1 if self.r2 is None else 2
            formatters = self.trimming['trim']['formatters']
            read_trim = trimmed['total_records_with_adapters']
            read_total = self.trimming['total_record_count']
            percent_pass = formatters['fraction_records_written']

            stats_dict = dict(stats_dict, **{
                'mean_read_length': formatters['total_bp_written'] / (
                    formatters['records_written'] * n),
                'percent_trim': (read_trim / (read_total * n)) * 100,
                'percent_discard': (1 - percent_pass) * 100
            })
        with open(filename, 'w') as fp:
            json.dump(stats_dict, fp)
