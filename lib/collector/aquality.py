# -*- coding: utf-8 -*

import json
import requests
import codecs
import datetime
import os
import ConfigParser
import io
import redis
import log
import header
import sys
import dateparser

log._logger.info('Start of the program for air quality')

root  = os.environ.get('BEGOOD_PATH')

# Connexion au serveur redis
c = redis.ConnectionPool(host='127.0.0.1', port='6379', db=0, decode_responses=True)
r = redis.StrictRedis(connection_pool=c)

conf = root+'/init/aquality.ini'

with open(conf) as f1:
    sample_config = f1.read()

config = ConfigParser.RawConfigParser(allow_no_value=True)
config.readfp(io.BytesIO(sample_config))

try:
	url = config.get('URL','url')
except Exception as e:
	log._logger.error("Except error " +str(e))

header.headerCheck(url, root)

try:
	content = requests.get(url)
	data = content.json()
except requests.ConnectionError as e:
	log._logger.error("Except error " +str(e))
except requests.Timeout as e:
	log._logger.error("Except error " +str(e))
except requests.TooManyRedirects as e:
	log._logger.error("Except error " +str(e))
except requests.HTTPError as e:
	log._logger.error("Except error " +str(e))

today = datetime.datetime.today()
tomorrow = today + datetime.timedelta(days = 1)
yesterday = today - datetime.timedelta(days = 1)

now = today.strftime("%Y/%m/%d")
toom = tomorrow.strftime("%Y/%m/%d")
yest = yesterday.strftime("%Y/%m/%d")

# Debut de le transaction
p = r.pipeline()
if r.exists("air-quality") == 1: 
	p.delete(*r.keys('air-quality'))

new_data = {}
new_data['list'] = []
for key,value in sorted(data.items()):
	if key == "error":
		log._logger.error("Error: Bad url request")
		sys.exit(1)
	else:
		if isinstance(value,list):
			if key == "features":
				for element in value:
					for sub_key, sub_value in element.items():
						for cle,valeur in sub_value.items():
							date = ""
							str_date = ""
							if cle == "date_ech":
								date = dateparser.parse(str(valeur))
								str_date = date.strftime("%Y/%m/%d")
							if str_date == now or str_date == yest or str_date == toom:
								dico = {}
								dico = sub_value
								new_data['list'].append(dico)
city_name = ""
i = 1
for key,value in sorted(new_data.items()):
	if isinstance(value,list):
		for element in value:
			for sub_key, sub_value in element.items():
				if sub_value == 'Montargis' or sub_value == 'Orleans':
					dico1 = {}
					str_qual = u''.join(element['qualif']).encode('utf-8')
					dico1['qualificatif'] = str_qual
					date = dateparser.parse(str(element['date_ech']))
					str_date = date.strftime("%Y/%m/%d")
					dico1['date_echeance'] = str_date
					dico1['valeur'] = element['valeur']
					dico1['y'] = element['y']
					dico1['x'] = element['x']
					str_nom_zone = u''.join(element['lib_zone']).encode('utf-8')
					dico1['nom_zone'] = str_nom_zone

					json_string = str(dico1)

					p.hset("air-quality", i, json.dumps(dico1, ensure_ascii=False).decode('UTF-8',"ignore"))
					i = i + 1

# Execution et fin de la transaction
p.execute()

log._logger.info('End of the program for air quality')
log._logger.info("-----------------------------------------------------------------------------------------")
