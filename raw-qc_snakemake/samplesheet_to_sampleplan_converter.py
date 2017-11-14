import sys
import os
import glob
import logging
from logging.handlers import RotatingFileHandler
import argparse


def parse_colnames(header_line):
    col_dict = dict()
    columns_names = header_line.rstrip('\n\r').split(",")
    for name in columns_names:
        col_dict[name.lower()] = columns_names.index(name)
    return col_dict


def parse_data(output_file, line, col_dict, output_path, run_name, exception):
    sep = ","
    infos = line.rstrip('\n\r').split(",")
    sample_id_key = [col_dict[i] for i in col_dict.keys() if "sample" in i and "id" in i]
    sample_id = infos[sample_id_key[0]]
    sample_name_key = [i for i in col_dict.keys() if "sample" in i and "name" in i]
    sample_name = infos[col_dict[sample_name_key[0]]]
    unique_sample_id = run_name + sample_id
    fastq_path = output_path + "/" + unique_sample_id
    fastq_nb = len(glob.glob1(fastq_path, "*.fastq*"))
    if fastq_nb == 1:
        R1_path = fastq_path + "/" + unique_sample_id + ".R1.fastq.gz"
        R1_path_check = os.path.isfile(R1_path)
        if R1_path_check:
            output_file.write(unique_sample_id + sep + sample_name + sep + R1_path + sep + "" + sep + "\n")
        else:
            logger.error("ERROR : The fastq files path '{0}' doesn't exist".format(R1_path))
            exception = True
    elif fastq_nb == 2:
        R1_path = fastq_path + "/" + unique_sample_id + ".R1.fastq.gz"
        R2_path = fastq_path + "/" + unique_sample_id + ".R2.fastq.gz"
        R1_path_check = os.path.isfile(R1_path)
        R2_path_check = os.path.isfile(R2_path)
        if R1_path_check and R2_path_check:
            output_file.write(unique_sample_id + sep + sample_name + sep + R1_path + sep + R2_path + sep + "\n")
        elif not R1_path_check or not R2_path_check:
            if not R1_path_check:
                wrong_path = R1_path
            if not R2_path_check:
                wrong_path = R2_path
            logger.error("ERROR : The fastq files path '{0}' doesn't exist".format(wrong_path))
            exception = True
        elif not R1_path_check and not R1_path_check:
            logger.error("ERROR : Fastq files paths '{0}' and '{1}' don't exist".format(R1_path, R2_path))
            exception = True
    else:
        logger.error("ERROR : Wrong number of fastq files '{0}' in the path '{1}' or this path doesn't exist. It must have one fastq file for SE samples or two fastq files for PE samples".format(fastq_nb, fastq_path))
        exception = True
    return exception


def parse_samplesheet(src, output_file, output_path, run_name):
    exception, header, data = False, False, False
    pre_line = str()
    col_dict = dict()
    line_number = 0
    for line in src:
        line_number += 1
        if not line[0] == "#":
            # Samplesheet format with Header information
            if "[Header]" in line.rstrip('\n\r') or header:
                header = True
                if "[Data]" in pre_line.rstrip('\n\r'):
                    data = True
                    col_dict = parse_colnames(line)
                elif data:
                    exception = parse_data(output_file, line, col_dict, output_path, run_name, exception)
                pre_line = line
            # Old samplesheet format
            else:
                if line_number == 1:
                    col_dict = parse_colnames(line)
                else:
                    exception = parse_data(output_file, line, col_dict, output_path, run_name, exception)
    return exception


if __name__ == "__main__":

    extended_help = """
    Several arguments can be used :

    arg input : string, take an input file name | REQUIRED
    arg log : string, take a log file name, if the file name exists, the file is update with new logs | REQUIRED

    """
    parser = argparse.ArgumentParser(description='', epilog=extended_help,
                                     formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-s', '--samplesheet', type=str, help='Enter a samplesheet file path')
    parser.add_argument('-r', '--run', type=str, help='Enter a run name')
    parser.add_argument('-o', '--output', type=str, help='Enter an output file path')
    parser.add_argument('-p', '--path', type=str, help='Enter input files path')
    parser.add_argument('-l', '--log', type=str, help='Enter a log file name')
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(2)
    args = parser.parse_args()

    ##LOGGING CONF##
    class LessThanFilter(logging.Filter):
        def __init__(self, exclusive_maximum, name=""):
            super(LessThanFilter, self).__init__(name)
            self.max_level = exclusive_maximum

        def filter(self, record):
            # non-zero return means we log this message
            return 1 if record.levelno < self.max_level else 0

    logger = logging.getLogger()
    logger.setLevel(logging.NOTSET)
    formatter = logging.Formatter('%(asctime)s :: %(levelname)s :: %(message)s')
    file_handler = RotatingFileHandler(args.log, 'a', 1000000, 1)
    file_handler.setLevel(logging.WARN)
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    logging_handler_out = logging.StreamHandler(sys.stdout)
    logging_handler_out.setLevel(logging.WARN)
    logging_handler_out.addFilter(LessThanFilter(logging.ERROR))
    logger.addHandler(logging_handler_out)

    logging_handler_err = logging.StreamHandler(sys.stderr)
    logging_handler_err.setLevel(logging.ERROR)
    logger.addHandler(logging_handler_err)
    ##LOGGING CONF##

    logger.info("### SAMPLESHEET TO SAMPLEPLAN CONVERTER BEGIN ####")

    try:
        source = open(args.samplesheet, "rU")
    except IOError as e:
        logger.critical("'{0}' : I/O error({1}): {2}".format(args.samplesheet, e.errno, e.strerror))
        sys.exit(2)
    path = args.output + "/" + args.run + "_SAMPLEPLAN"
    directory = args.output
    if not os.path.isdir(directory):
        os.mkdir(directory, 0755)
    try:
        output = open(path, "w")
    except IOError as e:
        logger.critical("'{0}' : I/O error({1}): {2}".format(path, e.errno, e.strerror))
        sys.exit(2)
    exception = parse_samplesheet(source, output, args.path, args.run)
    if exception:
        output.close()
        source.close()
        sys.exit(100)
    else:
        output.close()
        source.close()
