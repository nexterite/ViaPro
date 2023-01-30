# coding: utf-8
# coding: iso-8859-1

import zipfile
import requests
from io import BytesIO
from lxml import etree
import xmltodict
import json
import codecs
import os
import configparser
import io
import redis
import log
import header

log._logger.info("Start of the program for gaz station")

root  = os.environ.get('BEGOOD_PATH')

# Connexion au serveur redis
c = redis.ConnectionPool(host='127.0.0.1', port='6379', db=0,)
r = redis.StrictRedis(connection_pool=c)

conf = root+'/init/gstation.ini'
config = configparser.ConfigParser()
config.read(conf)

try:
    url = config["URL"]["url"]
except Exception as e:
    log._logger.error("Except error " +str(e))
    sys.exit(0)

header.headerCheck(url, root)

# get will bring prix_carburants.zip file in memory
response = requests.get(url)
if response.status_code != 200:
    log._logger.error("Except error " +str(response.status_code))
    log_check = False
    sys.exit(0)

# we will unzip the content and extracts its content into data directory
zip_ref = zipfile.ZipFile(BytesIO(response.content))
zip_ref.extractall("/tmp")

fichier = etree.parse("/tmp/PrixCarburants_instantane.xml")

# Debut de la transaction
p = r.pipeline()
if r.exists("gstation") == 1:
    p.delete(*r.keys('gstation'))

i = 1

for file in fichier.findall('pdv'):
    cp = file.get("cp")
    if cp <= "45800" and cp >= "45000":
        if 'latitude' in file.attrib:
            lat_stand = float(file.attrib['latitude']) / 100000
            file.attrib['latitude'] = str(lat_stand)
        if 'longitude' in file.attrib:
            long_stand = float(file.attrib['longitude']) / 100000
            file.attrib['longitude'] = str(long_stand)
        for horaire in file.findall('horaires'):
            horaire.getparent().remove(horaire)
        if 'id' in file.attrib or 'pop' in file.attrib or 'cp' in file.attrib:
            del file.attrib['id']
            del file.attrib['pop']
            del file.attrib['cp']
        for prix in file.findall('prix'):
            if 'id' in prix.attrib or 'maj' in prix.attrib:
                del prix.attrib['id']
                del prix.attrib['maj']
    else:
        file.getparent().remove(file)

try:
    with codecs.open('/tmp/PrixCarburants_instantane_Loiret.xml','w') as nouveau:
        nouveau.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n')
        e = etree.tostring(fichier,encoding="utf-8",pretty_print=True)
        nouveau.write(e.decode('utf-8'))

except IOError:
    log._logger.error('Problème rencontré lors de l\'écriture ...')
    exit(1)

with codecs.open('/tmp/PrixCarburants_instantane_Loiret.xml') as fd:
    data = xmltodict.parse(fd.read())

# #On ferme tous les fichiers du programme ouverts
# new.close()
# zip_ref.close()
dico = {}
dico['list'] = []
for key, value in data.items():
    for sub_key, sub_value in value.items():
        if isinstance(sub_value, list):
            for element in sub_value:
                json_string = str(element)
                p.hset("gstation", i, json.dumps(element, ensure_ascii=False).encode('utf-8'))
                i = i + 1

# Execution et fin de la transaction
p.execute()

log._logger.info("End of the program")
log._logger.info("-----------------------------------------------------------------------------------------")
