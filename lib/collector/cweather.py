# -*- coding: utf-8 -*-

import ConfigParser
import io
import os
import requests
import json
from datetime import datetime
import time
import codecs
import redis
import log
import header
import sys

log._logger.info("Start of the program for current weather")

root  = os.environ.get('BEGOOD_PATH')

# Connexion au serveur redis
c = redis.ConnectionPool(host='127.0.0.1', port='6379', db=0, decode_responses=True)
r = redis.StrictRedis(connection_pool=c)

conf = root+'/init/cweather.ini'

with open(conf) as f1:
    sample_config = f1.read()

config = ConfigParser.RawConfigParser(allow_no_value=True)
config.readfp(io.BytesIO(sample_config))
try:
	data = config.get('VILLE','department_file')
	delay = config.get('DELAY_EXECUTION', "DELAY")
except Exception as e:
	log._logger.error("Except error " +str(e))

with codecs.open(data,"r",encoding='utf-8') as f:
        fichier_entier = f.read()
        files = fichier_entier.split('\n')

# Debut de le transaction
p = r.pipeline()
if r.exists("current-weather") == 1: 
	p.delete(*r.keys('current-weather'))

for name in files:
    if name == '':
        break
    try:
        url_fr = config.get('URL','url_fr')+name+',fr'
        url_en = config.get('URL','url_en')+name+',fr'
        content_fr = requests.get(url_fr)
        content_en = requests.get(url_en)
    except requests.exceptions.Timeout as e:        
        log._logger.error("Except error " +str(e))
        sys.exit(1)
    except requests.exceptions.TooManyRedirects as e:
        log._logger.error("Except error " +str(e))
        sys.exit(1)
    except requests.exceptions.ConnectionError as e:
        log._logger.error("Except error " +str(e))
        sys.exit(1)
    except requests.exceptions.HTTPError as e:
        log._logger.error("Except error " +str(e))
        sys.exit(1)
    except requests.exceptions.RequestException as e:
        log._logger.error("Except error " +str(e))
        sys.exit(1)

    data = content_fr.json()
    data_en = content_en.json()

    dico = {}
    for key, value in sorted(data.items()):
        if key == "cod" and str(value) != "200":
            log._logger.error("Fatal error: Cod "+str(value)+", Message: "+data['message'])
            log._logger.info("End of the program cweather.py")
            log._logger.info("-----------------------------------------------------------------------------------------")
            sys.exit(1)

        if key == "sys":
            for cle, valeur in value.items():
                if cle == "sunrise":
                    value['sunrise'] = time.strftime('%H:%M', time.localtime(int(valeur)))
                if cle == "sunset":
                    value['sunset'] = time.strftime('%H:%M', time.localtime(int(valeur)))
                if key == "dt":
                    data['dt'] = time.strftime('%D %H:%M', time.localtime(int(data['dt'])))

            for key,value in sorted(data.items()):
                if key == 'name':
                    dico['name'] = data['name']
                    svg = data['name']
                if key == 'sys':
                    dico['sunrise'] = data['sys']['sunrise']
                    dico['sunset'] = data['sys']['sunset']
                if key == 'weather':
                    for element in value:
                        for cle,valeur in element.items():
                            dico['weather icon'] = element['icon']
                            dico['weather id'] = element['id']
                            dico['description'] = {}
                            dico['description']['fr'] = element['description']
                            dico['description']['en'] = data_en['weather'][0]['description']
                if key == 'coord':
                    dico['coord'] = {}
                    dico['coord']['lon'] = data['coord']['lon']
                    dico['coord']['lat'] = data['coord']['lat']
                if key == 'main':
                    celsius = data['main']['temp'] - 273.15
                    celsius_max = data['main']['temp_max'] - 273.15
                    celsius_min = data['main']['temp_min'] - 273.15
                    dico['temp'] = round(celsius,2)
                    dico['temp_max'] = round(celsius_max,2)
                    dico['temp_min'] = round(celsius_min,2)
                    dico['humidity'] = data['main']['humidity']
                    dico['pressure'] = data['main']['pressure']
                if key == 'wind':
                    dico['wind'] = data['wind']
                if key == 'dt':
                    timestamp = datetime.fromtimestamp(data['dt'])
                    date_string = timestamp.strftime('%Y-%m-%d %H:%M:%S')
                    dico['last_update'] = date_string


                json_string = str(dico)

#               p.hset("current-weather", name, json.dumps(dico, ensure_ascii=False).encode('utf-8'))
    p.hset("current-weather", name, json.dumps(dico, ensure_ascii=False).encode('utf-8'))

    time.sleep(float(delay))

# Execution et fin de la transaction
p.execute()

log._logger.info("End of the program")
log._logger.info("-----------------------------------------------------------------------------------------")
