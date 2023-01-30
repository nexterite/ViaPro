# coding: utf-8

import json
import codecs
import os
import io
import configparser
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
config = configparser.ConfigParser()
config.read(conf)

url = config["URL"]["URL"]

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

i = 1
 
for element in data:
    dico = {}
    dico['coordinates'] = []
    adresse = None
    if isinstance(element,dict):
        for key, value in element.items():
            if isinstance(value,dict):
                if 'commune' in value:
                    dico['city name'] = value['commune']
                if 'nb_places' in value:
                    dico['number of places'] = int(value['nb_places'])
                if 'rue' in value:
                    adresse = value['rue']
                    if 'numero' in value:
                        dico['adresse'] = adresse + " " + value['numero']
                if 'geo_point_2d' in value:
                    if isinstance(value['geo_point_2d'],list):
                        for elt in value['geo_point_2d']:
                            dico['coordinates'].append(elt)
#               for sub_key, sub_value in value.items():
#                   if sub_key == 'nb_places':
#                       dico['number of places'] = int(sub_value)
#                   if sub_key == 'numero':
#                       adresse = sub_value
#                    if sub_key == 'rue':
#                       dico['address'] = adresse+" "+sub_value
#                   if sub_key == 'geo_point_2d':
#                       if isinstance(sub_value,list):
#                           for elt in sub_value:
#                               dico['coordinates'].append(elt)

    json_string = str(dico)

    p.hset("bparking", i , json.dumps(dico, ensure_ascii=False).encode('utf-8'))
    
    i = i + 1
    
# Execution et fin de la transaction
p.execute()

log._logger.info("End of the program")
log._logger.info("-----------------------------------------------------------------------------------------")
