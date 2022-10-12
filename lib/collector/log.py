import logging
import os
import io
import codecs
import logging.config


root  = os.environ.get('BEGOOD_PATH')

logging.log_file = root+'/log/access.log'

logging.config.fileConfig(root+'/init/log.ini')

_logger = logging.getLogger()