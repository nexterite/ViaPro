# coding: utf-8

import log
import os
import io
import ConfigParser
import requests
import codecs
import json
import header
import redis
import sys
import csv

log._logger.info("Start of the program for risk_areas")

root = os.environ.get("BEGOOD_PATH")

# Connexion au serveur redis
c = redis.ConnectionPool(host='127.0.0.1', port='6379', db=0)
r = redis.StrictRedis(connection_pool=c)

if root:
    pass
else:
    log._logger.error("The environment variable entered does not exist")
    sys.exit()

conf = root+'/init/risk_areas.ini'

with open(conf) as f1:
    sample_config = f1.read()

config = ConfigParser.RawConfigParser(allow_no_value=True)
config.readfp(io.BytesIO(sample_config))

# Debut de la transaction
p = r.pipeline()
if r.exists("risk_areas") == 1:
    p.delete(*r.keys('risk_areas'))

i = 1

with open(root+'/data/risk_areas_url.csv') as csvfile:
	reader = csv.DictReader(csvfile)
	for row in reader:
		if "PPRT" in row['Name']:
			fichier_sortie = root+'/data/risk_areas_'+row['Name'][5:].replace(" ", "_")+'.json'
		else:
			fichier_sortie = root+'/data/risk_areas_'+row['Name'].replace(" ", "_")+'.json'

		dico = {}
		date = ""

		with codecs.open(fichier_sortie, "r", encoding="iso-8859-1") as f:
			data = f.read()

		header.headerCheck(row['Url'], root)

		json_data = json.loads(data)

		if "PPRT" in row['Name']:
			dico['subtype'] = "aleas"
			dico['type'] = "technogical_risk"
			dico['area name'] = row['Name'][5:]
			date = config.get(row['Name'][5:], "publication_date")
			dico['publication date'] = date
			dico['geojson'] = json_data

			p.hset("risk_areas", i, json.dumps(dico, ensure_ascii=False).encode('iso-8859-1').decode('utf-8','ignore'))

			i = i + 1

		elif 'SUR AREA' in row['Name']:
			dico['type'] = "flood"
			dico['subtype'] = "on aleas"
			dico['area name'] = row['Name']
			date = config.get("SUR AREA ORLEANS", "publication_date")
			dico['publication date'] = date
			dico['geojson'] = json_data
			
			p.hset("risk_areas", i, json.dumps(dico, ensure_ascii=False).encode('iso-8859-1').decode('utf-8','ignore'))

			i = i + 1

		else:
			dico['type'] = "flood"
			dico['subtype'] = "aleas"
			dico['area name'] = row['Name']
			date = config.get(row['Name'], "publication_date")
			dico['publication date'] = date
			dico['geojson'] = json_data
			
			p.hset("risk_areas", i, json.dumps(dico, ensure_ascii=False).encode('iso-8859-1').decode('utf-8','ignore'))

			i = i + 1

#Execution et fin de la transaction
p.execute()

log._logger.info("End of the program")
log._logger.info("-----------------------------------------------------------------------------------------")
