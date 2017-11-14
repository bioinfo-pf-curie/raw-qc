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
from curie.ws import handler
from curie.ws import wslib


def metadata_parsing(output_file, demand):
    exception = False
    bioinfoBedBool, speciesBool, sequencerBool, biologicalApplicationBool = False, False, False, False
    projectId, code, creationDate, project, user, runs, species, build, sequencer, bioinfoBed, demandDescription, SampleNumber, Team_leader, StateUpdateDate, agentName, laneOrRunNumber, analysis_type, biologicalApplication = "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""
    dataset_list = []
    sep = "\t"
    team_leader_unit = []
    try:
        rims_object = rimsHandler.demandWServiceRMS().findByCode(demand, ('project', 'projectId', 'code', 'contact:Team leader', 'user', 'runs', 'SampleNumber', 'creationDate', 'species', 'bioinfoVersionRG', 'sequencer', 'bioinfoTargetedPanelVersion', 'stateUpdateDate', 'laneOrRunNumber', 'biologicalApplication'))
    except:
        logger.critical("RIMS connection error")
        sys.exit(100)
    output_file.write("demand_code\tproject\tproject_id\tanalysis_type\tbiological_application\tsample_number\tlane_number\truns\tdatasets\tsequencer\tspecies\tbuild\tbed\tcreation_date\tstate_update_date\ttechnical_contact\tteam_leader|unit\tagent_name\n")
    fields_object = rims_object[0]
    for i in fields_object[0]:
        if i["key"] == "projectId":
            if not i["value"]:
                projectId = "Unknown"
            else:
                projectId = i["value"]
            logger.info(projectId)
        if i["key"] == "code":
            if not i["value"]:
                code = "Unknown"
            else:
                code = i["value"]
            logger.info(code)
        if i["key"] == "creationDate":
            if not i["value"]:
                creationDate = "Unknown"
            else:
                creationDate = i["value"]
            logger.info(creationDate)
        if i["key"] == "project":
            if not i["value"]:
                project = "Unknown"
            else:
                project = i["value"]
            logger.info(project)
        if i["key"] == "user":
            if not i["value"]:
                user = "Unknown"
            else:
                user = i["value"]
            logger.info(user)
        if i["key"] == "runs":
            if not i["value"]:
                runs = "Unknown"
            else:
                runs = i["value"]
            logger.info(runs)
        if i["key"] == "species":
            if not i["value"]:
                species = "Unknown"
            else:
                species = i["value"]
            logger.info(species)
            if species == "other":
                speciesBool = True
        if i["key"] == "bioinfoVersionRG":
            if not i["value"]:
                build = "Unknown"
            else:
                build = i["value"]
            logger.info(build)
        if i["key"] == "sequencer":
            if not i["value"]:
                sequencer = "Unknown"
            else:
                sequencer = i["value"]
            logger.info(sequencer)
            if i["value"] == "other":
                sequencerBool = True
        if i["key"] == "bioinfoTargetedPanelVersion":
            if not i["value"]:
                bioinfoBed = "Unknown"
            else:
                bioinfoBed = i["value"]
            if i["value"] == "Other":
                bioinfoBedBool = True
            logger.info(bioinfoBed)
#        if i["key"] == "demandDescription":
#            if not i["value"]:
#                demandDescription = "Unknown"
#            else:
#                demandDescription = i["value"].replace('\n', ' ').replace('\r', ' ').replace('\n\r', ' ')
#            logger.info(demandDescription)
        if i["key"] == "SampleNumber":
            if not i["value"]:
                SampleNumber = "Unknown"
            else:
                SampleNumber = i["value"]
            logger.info(SampleNumber)
        if i["key"] == "contact:Team leader":
            if not i["value"]:
                Team_leader = "Unknown"
            else:
                Team_leader = i["value"][1:len(i["value"])-1]
            logger.info(Team_leader)
#        if i["key"] == "contact:Scientific leader":
#            if not i["value"]:
#                Scientific_leader = "Unknown"
#            else:
#                Scientific_leader = i["value"][1:len(i["value"])-1]
#            logger.info(Scientific_leader)
        if i["key"] == "stateUpdateDate":
            if not i["value"]:
                stateUpdateDate = "Unknown"
            else:
                stateUpdateDate = i["value"]
            logger.info(stateUpdateDate)
        if i["key"] == "laneOrRunNumber":
            if not i["value"]:
                laneOrRunNumber = "Unknown"
            else:
                laneOrRunNumber = i["value"]
            logger.info(laneOrRunNumber)
        if i["key"] == "typeOfAnalysis":
            if not i["value"]:
                analysis_type = "Unknown"
            else:
                analysis_type = i["value"]
            logger.info(analysis_type)
        if i["key"] == "biologicalApplication":
            if not i["value"]:
                biologicalApplication = "Unknown"
            else:
                biologicalApplication = i["value"]
            if i["value"] == "Other":
                biologicalApplicationBool = True
            logger.info(biologicalApplication)
    runs_object = rims_object[1]
    for i in runs_object[0]:
        dataset = ""
        if i["agentName"]:
            agentName = i["agentName"]
            logger.info(agentName)
        try:
           dataset = i["analysis"][0]["dataset"]
        except:
            logger.info("There is no dataset or analysis for the run '{0}'".format(i["code"]))
        if dataset:
            dataset_list.append(dataset)
    if bioinfoBedBool:
        rims_object_2 = rimsHandler.demandWServiceRMS().findByCode(demand, ('bioinfoBed'))
        fields_object_2 = rims_object_2[0]
        for i in fields_object_2[0]:
            if i["key"] == "bioinfoBed":
                if not i["value"]:
                    bioinfoBed = "Unknown"
                else:
                    bioinfoBed = i["value"]
                logger.info(bioinfoBed)
    if speciesBool:
        rims_object_3 = rimsHandler.demandWServiceRMS().findByCode(demand, ('otherSpecies'))
        fields_object_3 = rims_object_3[0]
        for i in fields_object_3[0]:
            if i["key"] == "otherSpecies":
                if not i["value"]:
                    species = "Unknown"
                else:
                    species = i["value"]
                logger.info(species)
    if sequencerBool:
        rims_object_4 = rimsHandler.demandWServiceRMS().findByCode(demand, ('otherSequencer'))
        fields_object_4 = rims_object_4[0]
        for i in fields_object_4[0]:
            if i["key"] == "otherSequencer":
                if not i["value"]:
                    sequencer = "Unknown"
                else:
                    sequencer = i["value"]
                logger.info(sequencer)
    if biologicalApplicationBool:
        rims_object_5 = rimsHandler.demandWServiceRMS().findByCode(demand, ('otherBiologicalApplication'))
        fields_object_4 = rims_object_4[0]
        for i in fields_object_4[0]:
            if i["key"] == "otherBiologicalApplication":
                if not i["value"]:
                    biologicalApplication = "Unknown"
                else:
                    biologicalApplication = i["value"]
                logger.info(biologicalApplication)
    team_leader_list = Team_leader.split(',')
    for i in team_leader_list:
        try:
            team_leader_unit.append(i+" | "+kdiHandler.organisationWServiceKDI().findById(kdiHandler.userWServiceKDI().findByEmail('{0}'.format(i)).organisationId).name)
        except:
            team_leader_unit.append(i + " | Unknown")
            logging.info("Unknown mail adress in KDI : {0}".format(i))
#    scientific_leader_list = Scientific_leader.split(',')
#    for j in scientific_leader_list:
#        try:
#            scientific_leader_unit.append(j+"|"+kdiHandler.organisationWServiceKDI().findById(kdiHandler.userWServiceKDI().findByEmail('{0}'.format(j)).organisationId).name)
#        except:
#            scientific_leader_unit.append(j + "|Unknown")
#            logging.info("Unknown mail adress in KDI : {0}".format(j))
    team_leader_str = ','.join([x.encode('UTF8') for x in team_leader_unit])
#    scientific_leader_str = ','.join([x.encode('UTF8') for x in scientific_leader_unit])
    output_file.write(str(code) + sep + str(project) + sep + str(projectId) + sep + str(analysis_type) + sep + str(biologicalApplication) + sep + str(SampleNumber) + sep + str(laneOrRunNumber) + sep + str(runs) + sep + str(dataset_list)[1:len(str(dataset_list))-1] + sep + str(demandDescription) + sep + str(sequencer) + sep + str(species) + sep + str(build) + sep + str(bioinfoBed) + sep + str(creationDate) + sep + str(stateUpdateDate) + sep + str(user) + sep + team_leader_str + sep + str(agentName) + "\n")
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
