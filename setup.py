# coding: utf-8
__revision__ = "$Id$"
import sys
import os
from setuptools import setup, find_packages
import glob


_MAJOR               = 0
_MINOR               = 2
_MICRO               = 0
version              = '%d.%d.%d' % (_MAJOR, _MINOR, _MICRO)
release              = '%d.%d' % (_MAJOR, _MINOR)

metainfo = {
    'authors': {
        'Desvillechabrol':('Dimitri Desvillechabrol',
                           'dimitri.desvillechabrol@curie.fr'),
        },
    'version': version,
    'license' : 'BSD',
    'download_url': [],
    'url': ['https://gitlab.curie.fr/ddesvill/autotropos/'],
    'description':'A pipeline to control the quality and trim adapters of FastQ files.',
    'platforms' : ['Linux', 'Unix', 'MacOsX'],
    'keywords': ['trimming', 'atropos', 'QC'],
    'classifiers' : [
          'Development Status :: 1 - Planning',
          'Intended Audience :: Developers',
          'Intended Audience :: Science/Research',
          'License :: OSI Approved :: BSD License',
          'Operating System :: OS Independent',
          'Programming Language :: Python :: 3.6',
          'Topic :: Software Development :: Libraries :: Python Modules',
          'Topic :: Scientific/Engineering :: Bio-Informatics',
          'Topic :: Scientific/Engineering :: Information Analysis',
    ]
}

with open('README.md') as f:
    readme = f.read()

from distutils.core import setup, Extension

setup(
    name             = 'rawqc',
    version          = version,
    maintainer       = metainfo['authors']['Desvillechabrol'][0],
    maintainer_email = metainfo['authors']['Desvillechabrol'][1],
    author           = metainfo['authors']['Desvillechabrol'][0],
    author_email     = metainfo['authors']['Desvillechabrol'][1],
    long_description = readme,
    keywords         = metainfo['keywords'],
    description = metainfo['description'],
    license          = metainfo['license'],
    platforms        = metainfo['platforms'],
    url              = metainfo['url'],
    download_url     = metainfo['download_url'],
    classifiers      = metainfo['classifiers'],
    zip_safe = False,
    packages = find_packages(),
    scripts = [],
    install_requires = [ 
        'atropos', 'click', 'numpy', 'pexpect',
    ],
    # This is recursive include of data files
    exclude_package_data = {"": ["__pycache__"]},
    package_data = {
        '': ['pipeline/*', 'pipeline/scripts/*', 'config/*'],
        'rawqc.resources.images': ['*'],
        'rawqc.resources.data': ['*'],
    },
    entry_points = {
        'console_scripts':[
            'rawqc_atropos=rawqc.scripts.rawqc_atropos:main',
            'rawqc_basic_metrics=rawqc.scripts.rawqc_basic_metrics:main',
            'raw-qc=rawqc.scripts.rawqc:main',
            'rawqc_populate_multiqc=rawqc.scripts.rawqc_populate_multiqc:main',
        ],
        'multiqc.modules.v1':[
            'rawqc_metrics=rawqc.multiqc.metrics:MultiqcModule',
            'rawqc_trimming=rawqc.multiqc.trimming:MultiqcModule',
        ],
        'multiqc.hooks.v1':[
            'before_config=rawqc.multiqc:multiqc_rawqc_config',
        ],
    },
)
