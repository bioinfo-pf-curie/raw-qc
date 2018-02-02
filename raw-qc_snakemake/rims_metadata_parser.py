#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
Created on Sep. 13, 2017

@authors: Mathieu Valade, Institut Curie, Paris
@contacts: mathieu.valade@curie.fr
@project: rims_metadata_parser
@githuborganization: U900
"""

import sys
import os
import logging
from logging.handlers import RotatingFileHandler
import argparse
import collections
from curie.ws import handler
from curie.ws import wslib


def metadata_parsing(output_file, demand):
    exception = False
    bioinfoBedBool, speciesBool, sequencerBool, biologicalApplicationBool = False, False, False, False
    Team_leader = ""
    metadata_dict = collections.OrderedDict([('demand_code',''),('project_name',''),('project_id',''),('analysis_type',''),('biological_application',''),('sample_number',''),('lane_number',''),('runs',''),('datasets',''),('sequencer',''),('species',''),('build',''),('bed',''),('creation_date',''),('state_update_date',''),('technical_contact',''),('team_leader|unit',''),('agent_name','')])
    dataset_list = []
    sep = "\t"
    team_leader_unit = []
    try:
        rims_object = rimsHandler.demandWServiceRMS().findByCode(demand, ('project', 'projectId', 'code', 'contact:Team leader', 'user', 'runs', 'SampleNumber', 'creationDate', 'species', 'bioinfoVersionRG', 'sequencer', 'bioinfoTargetedPanelVersion', 'stateUpdateDate', 'laneOrRunNumber', 'biologicalApplication', 'otherSpecies', 'bioinfoBed', 'otherSequencer', 'otherBiologicalApplication'))
    except Exception as e:
        logger.exception("RIMS connection error")
        sys.exit(100)
    fields_object = rims_object[0]
    for i in fields_object[0]:
        if i["key"] == "projectId":
            if not i["value"]:
                metadata_dict['project_id'] = "Unknown"
            else:
                metadata_dict['project_id'] = i["value"]
        if i["key"] == "code":
            if not i["value"]:
                metadata_dict['demand_code'] = "Unknown"
            else:
                metadata_dict['demand_code'] = i["value"]
        if i["key"] == "creationDate":
            if not i["value"]:
                metadata_dict['creation_date'] = "Unknown"
            else:
                metadata_dict['creation_date'] = i["value"]
        if i["key"] == "project":
            if not i["value"]:
                metadata_dict['project_name'] = "Unknown"
            else:
                metadata_dict['project_name'] = i["value"]
        if i["key"] == "user":
            if not i["value"]:
                metadata_dict['technical_contact'] = "Unknown"
            else:
                metadata_dict['technical_contact'] = i["value"]
        if i["key"] == "runs":
            if not i["value"]:
                metadata_dict['runs'] = "Unknown"
            else:
                metadata_dict['runs'] = i["value"]
        if i["key"] == "species":
            if not i["value"] == "other":
                if not i["value"]:
                    metadata_dict['species'] = "Unknown"
                else:
                    metadata_dict['species'] = i["value"]
            elif i["value"] == "other":
                speciesBool = True
        if speciesBool:
            if i["key"] == "otherSpecies":
                if not i["value"]:
                    metadata_dict['species'] = "Unknown"
                else:
                    metadata_dict['species'] = i["value"]
        if i["key"] == "bioinfoVersionRG":
            if not i["value"]:
                metadata_dict['build'] = "Unknown"
            else:
                metadata_dict['build'] = i["value"]
        if i["key"] == "sequencer":
            if not i["value"] == "other":
                if not i["value"]:
                    metadata_dict['sequencer'] = "Unknown"
                else:
                    metadata_dict['sequencer'] = i["value"]
            elif i["value"] == "other":
                sequencerBool = True
        if sequencerBool:
            if i["key"] == "otherSequencer":
                if not i["value"]:
                    metadata_dict['sequencer'] = "Unknown"
                else:
                    metadata_dict['sequencer'] = i["value"]
        if i["key"] == "bioinfoTargetedPanelVersion":
            if not i["value"] == "other":
                if not i["value"]:
                    metadata_dict['bed'] = "Unknown"
                else:
                    metadata_dict['bed'] = i["value"]
            elif i["value"] == "other":
                bioinfoBedBool = True
        if bioinfoBedBool:
            if i["key"] == "bioinfoBed":
                if not i["value"]:
                    metadata_dict['bed'] = "Unknown"
                else:
                    metadata_dict['bed'] = i["value"]
        if i["key"] == "SampleNumber":
            if not i["value"]:
                metadata_dict['sample_number'] = "Unknown"
            else:
                metadata_dict['sample_number'] = i["value"]
        if i["key"] == "contact:Team leader":
            if not i["value"]:
                Team_leader = "Unknown"
            else:
                Team_leader = i["value"][1:len(i["value"])-1]
        if i["key"] == "stateUpdateDate":
            if not i["value"]:
                metadata_dict['state_update_date'] = "Unknown"
            else:
                metadata_dict['state_update_date'] = i["value"]
        if i["key"] == "laneOrRunNumber":
            if not i["value"]:
                metadata_dict['lane_number'] = "Unknown"
            else:
                metadata_dict['lane_number'] = i["value"]
        if i["key"] == "typeOfAnalysis":
            if not i["value"]:
                metadata_dict['analysis_type'] = "Unknown"
            else:
                metadata_dict['analysis_type'] = i["value"]
        if i["key"] == "biologicalApplication":
            if not i["value"] == "other":
                if not i["value"]:
                    metadata_dict['biological_application'] = "Unknown"
                else:
                    metadata_dict['biological_application'] = i["value"]
            elif i["value"] == "other":
                biologicalApplicationBool = True
        if biologicalApplicationBool:
            if i["key"] == "otherBiologicalApplication":
                if not i["value"]:
                    metadata_dict['biological_application'] = "Unknown"
                else:
                    metadata_dict['biological_application'] = i["value"]
    runs_object = rims_object[1]
    for i in runs_object[0]:
        dataset = ""
        if i["agentName"]:
            metadata_dict['agent_name'] = i["agentName"]
        else:
            metadata_dict['agent_name'] = "Unknown"
        try:
           dataset = i["analysis"][0]["dataset"]
        except:
            logger.info("There is no dataset or analysis for the run '{0}'".format(i["code"]))
        if dataset:
            dataset_list.append(dataset)
    if dataset_list:
        metadata_dict['datasets'] = str(dataset_list)[1:len(str(dataset_list))-1]
    team_leader_list = Team_leader.split(',')
    for i in team_leader_list:
        try:
            team_leader_unit.append(i+" | "+kdiHandler.organisationWServiceKDI().findById(kdiHandler.userWServiceKDI().findByEmail('{0}'.format(i)).organisationId).name)
        except:
            team_leader_unit.append(i + " | Unknown")
            logging.info("Unknown mail adress in KDI : {0}".format(i))
    team_leader_str = ','.join([x.encode('UTF8') for x in team_leader_unit])
    metadata_dict['team_leader|unit'] = team_leader_str
    for i in metadata_dict.items():
        output_file.write(i[0] + "\t" + i[1] + "\n")
    return exception

if __name__ == "__main__":

    extended_help = """
    Several arguments can be used :

    aarg env : string, take the RIMS env : dev, valid or prod | REQUIRED
    arg output : string, take an output file path | REQUIRED
    arg log : string, take a log file name, if the file name exists, the file is update with new logs | REQUIRED
    arg demand : string, take a demand name | REQUIRED
    arg run : string, take a run name | REQUIRED
    """
    parser = argparse.ArgumentParser(description='', epilog=extended_help,
                                     formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-e', '--env', type=str, help='Enter a RIMS env : dev, valid or prod')
    parser.add_argument('-o', '--output', type=str, help='Enter an output file path')
    parser.add_argument('-r', '--run', type=str, help='Enter a RUN name')
    parser.add_argument('-l', '--log', type=str, help='Enter a log file name')
    parser.add_argument('-d', '--demand', type=str, help='Enter a run name')
    parser.add_argument('-x', '--xenogref', type=str, help='Enter a run name')
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

    logger.info("### RIMS METADATA PARSER BEGIN ####")
    file_handler.setLevel(logging.WARN)
    logging_handler_out.setLevel(logging.WARN)
    if args.env == "dev" or args.env == "valid" or args.env == "prod":
        conf = '/data/kdi_{0}/WS/conf/wsconfig.xml'.format(args.env)
        rimsHandler = handler.Handler('rims', '{0}'.format(args.env), 'ngsdm', conf, admin_mode=False)  # rims or another application
        kdiHandler = handler.Handler('kdi', '{0}'.format(args.env), 'ngsdm', conf, admin_mode=False)
    else:
        logger.critical("Wrong KDI env name given : '{0}'; this argument must be 'dev' or 'valid' or 'prod'".format(args.env))
        sys.exit(100)
    path = args.output + "/" + args.run + "-rims_metadata.tsv"
    try:
        output = open(path, "w")
    except IOError as e:
        logger.critical("'{0}' : I/O error({1}): {2}".format(args.output, e.errno, e.strerror))
        sys.exit(100)
    exception = metadata_parsing(output, args.demand)
    output.close()
    if exception:
        os.remove(path)
        sys.exit(100)
