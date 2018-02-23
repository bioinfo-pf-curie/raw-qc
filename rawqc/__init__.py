import pkg_resources
try:
    version = pkg_resources.require("raw-qc")[0].version
except:
    version = ">=0.1.0"

import logging

handler = logging.StreamHandler()
handler.setFormatter(logging.Formatter(
    "%(asctime)s - %(levelname)-8s %(message)s",
    "%Y-%m-%d %H:%M:%S"
))
logger = logging.getLogger(__name__)
logger.propagate = False
logger.setLevel('INFO')
logger.addHandler(handler)

from .atropos import Atropos
