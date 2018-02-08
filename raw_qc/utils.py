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
import os
import shutil
import tempfile
import pkg_resources

from raw_qc import logger


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

def raw_qc_data(filename=None, where=None):
    """ Return full path of an raw_qc resource data file.

    :param str filename: a valid filename to be found.
    :param str where: one of the registered data directory
    :return: the path of file.

    Type the function name with "*" parameter to get a list of
    available files. Withe where argument set, the function returns a 
    list of files. Without the where argument, a dictionary is returned where
    keys correspond to the registered directories::

        filenames = raw_qc_data('*', where='data')

    .. note:: this does not handle wildcards. The * means retrieve all files.

    """
    rawqc_path = get_package_location('raw_qc')
    resources = os.sep.join([raw_qc_path, 'raw_qc', 'resources'])
    directories = ['data', 'images']
