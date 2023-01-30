
# -*- coding: utf-8 -*

import configparser
import io
import requests
import json
import codecs
import os
import redis
import time
import log
import sys

log._logger.info("Start of the program for forecast weather")

try:
    root = os.environ.get('BEGOOD_PATH')
except Exception as e:
    log._logger.error("Except error " +str(e))

# Connexion au serveur redis
c = redis.ConnectionPool(host='127.0.0.1', port='6379', db=0, decode_responses=True)
r = redis.StrictRedis(connection_pool=c)

conf = root+'/init/fweather.ini'
output = root+'/data/fweather.json'

with open(conf) as f1:
    sample_config = f1.read()

config = configparser.RawConfigParser(allow_no_value=True)
config.readfp(io.BytesIO(sample_config))

try:
    data = config.get('VILLE','department_file')
    delay = config.get('DELAY_EXECUTION', "DELAY")
except Exception as e:
    log._logger("Except error " +str(e))

with codecs.open(data,"r",encoding='utf-8') as f :
    fichier_entier = f.read()
    files = fichier_entier.split('\n')

new_data = {}
new_data['list'] = []


fichier = codecs.open(output, 'w+', encoding="UTF-8")

# Debut de le transaction
p = r.pipeline()
if r.exists("forecast-weather") == 1:
    p.delete(*r.keys('forecast-weather'))

#On parcourt à nouveau le fichier avec le caractère de fin de ligne
for name in files :
    if name == '':
        break
    #On récupére l'api en lançant une requête http et on donne le nom de la commune à chaque boucle
    try:
        url_fr = config.get('URL','url_fr')+name+',fr'
        url_en = config.get('URL','url_en')+name+',fr'
    except Exception as e:
        log._logger.error("Except error " +str(e))
        sys.exit(1)

    try:
    #On stocke les retours de la requête http dans une variable
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

    #On parse les resultats en format json
    data_fr = content_fr.json()
    data_en = content_en.json()

    for key, value in data_fr.items():
        if key == "cod" and str(value) != "200":
            log._logger.error("Fatal error: cod "+str(value)+", message: "+data_fr['message'])
            log._logger.info("End of the program fweather.py")
            log._logger.info("-----------------------------------------------------------------------------------------")
            sys.exit()
        i = 0
        data = {}
        data['list'] = []
        new_data = {}
        new_data['list'] = []
        for key_en, value_en in data_en.items():
            if isinstance(value_en,list):
                for element in value_en:
                    if isinstance(element,dict):
                        for sub_key, sub_value in element.items():
                            if isinstance(sub_value,list):
                                for elt in sub_value:
                                    dico = {}
                                    dico['description'] = elt['description']
                                    new_data['list'].append(dico)

        for key_fr, value_fr in data_fr.items():
            if isinstance(value_fr,list):
                for element in value_fr:
                    if isinstance(element,dict):
                        for sub_key, sub_value in element.items():
                            if isinstance(sub_value,list):
                                for elt in sub_value:
                                    dico = {}
                                    dico['description'] = {}
                                    dico['description']['fr'] = elt['description']
                                    dico['description']['en'] = new_data['list'][i]['description']
                                    dico['update'] = element['dt_txt']
                                    celsius = element['main']['temp'] - 273.15
                                    celsius_min = element['main']['temp_min'] - 273.15
                                    celsius_max = element['main']['temp_max'] - 273.15
                                    dico['temp'] = round(celsius,2)
                                    dico['temp_max'] = round(celsius_max,2)
                                    dico['temp_min'] = round(celsius_min,2)
                                    dico['weather icon'] = elt['icon']
                                    dico['weather id'] = elt['id']
                                    data['list'].append(dico)
                                    i = i + 1

                data['name'] = {}
                data['coord'] = {}
                data['coord']['lat'] = data_fr['city']['coord']['lat']
                data['coord']['lon'] = data_fr['city']['coord']['lon']
                data['name'] = name

                json_string = str(data)

                p.hset("forecast-weather", name, json.dumps(data, ensure_ascii=False).encode('utf-8'))

        time.sleep(float(delay))

# Execution et fin de la transaction
p.execute()

log._logger.info("End of the program")
log._logger.info("-----------------------------------------------------------------------------------------")
