# coding: utf-8

import json
import codecs
import os
import io
import ConfigParser
from datetime import datetime, timedelta
import log
import sys
import requests
import header 
import redis

log._logger.info("Start of the program for bike parking")

root = os.environ.get('BEGOOD_PATH')

# Connexion au serveur redis
c = redis.ConnectionPool(host='127.0.0.1', port='6379', db=0,)
r = redis.StrictRedis(connection_pool=c)

if root:
    pass
else:
    log._logger.error("The environment variable entered does not exist")
    sys.exit()

conf = root+'/init/bparking.ini'


with codecs.open(conf) as f1:
    sample_config = f1.read()

config = ConfigParser.RawConfigParser(allow_no_value=True)
config.readfp(io.BytesIO(sample_config))

url = config.get("URL", "URL")

try:
	content = requests.get(url)
	data = content.json()
except requests.exceptions.RequestException as e:
	log._logger.error("Program stopping because the url is not in correct format or invalid")
	sys.exit()

header.headerCheck(url, root)
#print("Ca passe") 

# Debut de le transaction
p = r.pipeline()
if r.exists("bparking") == 1:
    p.delete(*r.keys('bparking'))


if r.exists("bparking-id") == 1:
    p.delete(*r.keys('bparking-id'))

p.set('bparking-id', 1)

# p.execute()

 
for element in data:
    dico = {}
    dico['coordinates'] = []
    adresse = None
    if isinstance(element,dict):
        for key, value in element.items():
            if isinstance(value,dict):
                for sub_key, sub_value in value.items():
                    if sub_key == 'commune':
                        dico['city name'] = sub_value
                    if sub_key == 'nb_places':
                        dico['number of places'] = sub_value
                    if sub_key == 'numero':
                        adresse = sub_value
                    if sub_key == 'rue':
                        dico['address'] = adresse +" "+sub_value
                    if sub_key == 'geo_point_2d':
                        if isinstance(sub_value,list):
                            for elt in sub_value:
                                dico['coordinates'].append(elt)
    json_string = str(dico)

    p.hset("bparking", r.get('bparking-id'), json.dumps(dico, ensure_ascii=False).encode('utf-8'))
    
    r.incr('bparking-id')
    # p.hset("bparking", r.get('bparking-id'),json_string.decode('iso-8859-1').encode("UTF-8","ignore"))
    
# Execution et fin de la transaction
p.execute()

log._logger.info("End of the program")
log._logger.info("-----------------------------------------------------------------------------------------")
