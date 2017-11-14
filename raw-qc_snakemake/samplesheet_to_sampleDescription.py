import sys
import os
import logging
from logging.handlers import RotatingFileHandler
import argparse


def parse_data(output_file, line, col_dict, run_name):
    sep = "|"
    infos = line.rstrip('\n\r').split(",")
    sample_id = infos[col_dict["sample_id"]]
    sample_name = infos[col_dict["sample_name"]]
    output_file.write(run_name + sample_id + sep + sample_name + "\n")


def parse_colnames(header_line):
    col_dict = dict()
    columns_names = header_line.rstrip('\n\r').split(",")
    for name in columns_names:
        col_dict[name.lower()] = columns_names.index(name)
    return col_dict


def parse_samplesheet(src, output_file, run_name):
    pre_line = str()
    col_dict = dict()
    data = False
    for line in src:
        if not line[0] == "#":
            if "[Data]" in pre_line.rstrip('\n\r'):
                data = True
                col_dict = parse_colnames(line)
            elif data:
                parse_data(output_file, line, col_dict, run_name)
            pre_line = line


if __name__ == "__main__":

    extended_help = """
    Several arguments can be used :

    arg samplesheet : string, take an samplesheet file name | REQUIRED
    arg output : string, take an output file path | REQUIRED
    arg log : string, take a log file name, if the file name exists, the file is update with new logs | REQUIRED
    arg project : string, take a project name | REQUIRED
    arg run : string, take a run name | REQUIRED
    """
    parser = argparse.ArgumentParser(description='', epilog=extended_help,
                                     formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-s', '--samplesheet', type=str, help='Enter a samplesheet file path')
    parser.add_argument('-o', '--output', type=str, help='Enter an output file path')
    parser.add_argument('-l', '--log', type=str, help='Enter a log file name')
    parser.add_argument('--project', type=str, help='Enter a project name')
    parser.add_argument('--run', type=str, help='Enter a run name')
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(2)
    args = parser.parse_args()

    ##LOG##
    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG)
    formatter = logging.Formatter('%(asctime)s :: %(levelname)s :: %(message)s')
    file_handler = RotatingFileHandler(args.log, 'a', 1000000, 1)
    file_handler.setLevel(logging.WARN)
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)
    steam_handler = logging.StreamHandler()
    steam_handler.setLevel(logging.WARN)
    logger.addHandler(steam_handler)
    ##LOG##

    try:
        source = open(args.samplesheet, "rU")
    except IOError as e:
        logger.critical("'{0}' : I/O error({1}): {2}".format(args.samplesheet, e.errno, e.strerror))
        sys.exit(2)
    path = args.output + "/" + args.project + "-" + args.run + "/archive/" + args.run + ".sampleDescription.txt"
    directory = args.output + "/" + args.project + "-" + args.run
    if not os.path.isdir(directory):
        os.mkdir(directory, 0755);
    try:
        output = open(path, "w")
    except IOError as e:
        logger.critical("'{0}' : I/O error({1}): {2}".format(path, e.errno, e.strerror))
        sys.exit(2)
    parse_samplesheet(source, output, args.run)