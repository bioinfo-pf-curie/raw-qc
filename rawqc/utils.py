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
import glob
import os
import shutil
import tempfile
import pkg_resources

from rawqc import logger


__all__ = ['TempFile']

class TempFile(object):
    """A small wrapper around tempfile.NamedTemporaryFile function
    ::
        f = TempFile(suffix="csv")
        f.name
        f.delete() # alias to delete=False and close() calls
    """
    def __init__(self, suffix='', dir=None):
        self.temp = tempfile.NamedTemporaryFile(suffix=suffix, delete=False,
                                                dir=dir)
        self._name = self.temp.name

    def delete(self):
        try:
            self.temp._closer.delete = True
        except:
            self.temp.delete = True
        self.temp.close()

    @property
    def name(self):
        return self._name

    def __exit__(self, type, value, traceback):
        try:
            self.delete()
        except AttributeError:
            pass
        finally:
            self.delete()

    def __enter__(self):
        return self

def copy_file(src, dst):
    if os.path.exists(dst):
        if os.path.isdir(dst):
            logger.error("The destination file already exist as a directory.")
            raise ValueError
    shutil.copyfile(src, dst)

def get_package_location(package):
    """Return physical location of a package"""
    try:
        info = pkg_resources.get_distribution(package)
        location = info.location
    except pkg_resources.DistributionNotFound as err:
        logger.error("package provided (%s) not installed." % package)
        raise
    return location

def rawqc_data(filename=None):
    """Return full path of a raw-qc resource data file in `resources/data`.

    :param str filename: a valid filename to be found in `resources/data`.
    :return: the path of file.
    """
    rawqc_path = get_package_location('rawqc')
    data_dir = os.sep.join([rawqc_path, 'rawqc', 'resources', 'data'])
    if filename:
        filename = os.sep.join([data_dir, filename])
        if os.path.exists(filename):
            return filename
        raise Exception("Unknown data file {}. Type sequana_data() to get a "
                        "list of valid names".format(filename))
    else:
        to_ignore = {'__init__.py', '__pycache__'}
        found = [
            filename
            for filename in glob.glob(data_dir + os.sep + '*')
            if not filename.endswith('.pyc') or filename not in to_ignore
        ]
        return found
