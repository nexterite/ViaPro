# coding: utf-8
# coding: iso-8859-1

import urllib
import zipfile
from lxml import etree
import xmltodict
import json
import codecs
import os
import ConfigParser
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
with open(conf) as f1:
    sample_config = f1.read()

config = ConfigParser.RawConfigParser(allow_no_value=True)
config.readfp(io.BytesIO(sample_config))

try:
    url = config.get("URL","url")
except Exception as e:
    log._logger.error("Except error " +str(e))

header.headerCheck(url, root)
#print ('Ca passe')

#On utilise la librairie urllib pour envoyer une requête http et récuperer l'api
urllib.urlretrieve(url, "/tmp/prix_carburants.zip")

#On dézipper le fichier réçu et on l'ouvre en mode lecture
zip_ref = zipfile.ZipFile("/tmp/prix_carburants.zip", 'r')
#On extracte le fichier dézippé dans le dossier archive
zip_ref.extractall("/tmp")
#On parse le fichier dézippé pour faciliter son exploitation
fichier = etree.parse("/tmp/PrixCarburants_instantane.xml")

# Debut de la transaction
p = r.pipeline()
if r.exists("gstation") == 1:
    p.delete(*r.keys('gstation'))

i = 1

#On parcourt le fichier avec une boucle for
for file in fichier.findall('pdv'):
    #On récupérer tous les codes postaux
    cp = file.get("cp")
    #On fait un filtre pour récuperer que les codes postaux du dpt de Loiret
    if cp <= "45800" and cp >= "45000":
        if 'latitude' in file.attrib:
            #On modifie la valeur de l'attribut latitude en le divisant par 100000
            lat_stand = float(file.attrib['latitude']) / 100000
            file.attrib['latitude'] = str(lat_stand)
        if 'longitude' in file.attrib:
            #On modifie la valeur de l'attribut longitude en le divisant par 100000
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
	#On supprime les données qui ne concernent pas la première condition
	file.getparent().remove(file)

try:
    #On ouvre (ou crée) le fichier xml pour travailler avec
    with codecs.open('/tmp/PrixCarburants_instantane_Loiret.xml','w') as nouveau:
        #En-tête du fichier xml
        nouveau.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n')
        #On écrit tous les éléments précédemment déclarer
        nouveau.write(etree.tostring(fichier,encoding="utf-8",pretty_print=True))
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
