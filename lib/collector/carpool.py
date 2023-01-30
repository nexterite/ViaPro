# coding: utf-8

import json
import codecs
import io
import os
import configparser
from datetime import datetime, timedelta
import log
import sys
import requests
import csv
import header
import redis

log._logger.info("Start of the program for carpool areas")


root = os.environ.get('BEGOOD_PATH')

# Connexion au serveur redis
c = redis.ConnectionPool(host='127.0.0.1', port='6379', db=0)
r = redis.StrictRedis(connection_pool=c)

if root:
    pass
else:
    log._logger.error("The environment variable entered does not exist")
    sys.exit()

conf = root+'/init/carpool.ini'
config = configparser.ConfigParser()
config.read(conf)

url = config["URL"]["URL"]

response = requests.get(url)
if response.status_code != 200:
    log._logger.error("Except error " +str(response.status_code))
    sys.exit(0)

response.encoding = 'UTF-8'
reader = csv.DictReader(io.StringIO(response.text), delimiter=';', quoting=csv.QUOTE_NONE)

# Debut de le transaction
p = r.pipeline()
if r.exists("carpool") == 1:
    p.delete(*r.keys('carpool'))

if r.exists("carpool-id") == 1:
    p.delete(*r.keys('carpool-id'))

i = 1

for row in reader:
    if row['Code_Postal'] == None:
        continue

    if row['Code_Postal'] >= "45000" and row['Code_Postal'] < "46000" and row['Pays'] == 'France':
        dico = {}
        dico['coordinates'] = {}
        dico['city name'] = row['Ville']
        dico['address'] = row['Adresse']
        dico['coordinates']['latitude'] = row['Lat']
        dico['coordinates']['longitude'] = row['Lng']
            
        json_string = str(dico)

        p.hset("carpool", i, json.dumps(dico, ensure_ascii=False))

        i = i + 1
        # p.hset("carpool", r.get("carpool-id"), json_string.decode('iso-8859-1').encode("UTF-8","ignore"))
       
# Execution et fin de la transaction
p.execute()

log._logger.info("End of the program")
log._logger.info("-----------------------------------------------------------------------------------------")
