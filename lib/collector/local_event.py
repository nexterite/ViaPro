# coding: utf-8

import log
import requests
import configparser
import io
import codecs
from datetime import datetime
import time
import json
import sys
import fonct_local_event
import header
import redis

log._logger.info("Start of the program for open agenda Orléans Métropôle and Loiret")

try:
    root = fonct_local_event.root
except Exception as e:
    log._logger.error("Except error " +str(e))

# Connexion au serveur redis
c = redis.ConnectionPool(host='127.0.0.1', port='6379', db=0,)
r = redis.StrictRedis(connection_pool=c)

# Récupération du fichier de configuration du programme. Ce dernier contient les deux url (OM et Loiret)
conf = root+'/init/local_event.ini'
config = configparser.ConfigParser()
config.read(conf)

# offset et limit sont des paramètres de nos deux url
offset= 0
limit = 100

# 14400 represente la conversion en secondes de 4 heures.
# Chaque que le programme est lancé, on doit v&rifier si la difference entre l'heure de démarrage de l'évènement et l'heure de lancement du programme
# est inférieur à 14400 si oui le programme considere l'evenement sinon il est ignoré
timeLimitOrleans = 14400

# 21600 represente la conversion en secondes de 6 heures.
# Chaque que le programme est lancé, on doit v&rifier si la difference entre l'heure de démarrage de l'évènement et l'heure de lancement du programme
# est inférieur à 21600 si oui le programme considere l'evenement sinon il est ignoré
timeLimitLoiret = 21600

now = datetime.now()

format = "%Y-%m-%d %H:%M:%S"
# On récupere la date du jour pour pouvoir faire la difference avec les variables timeLimitLoiret et timeLimitOrleans
today = now.strftime(format)

# Ce fichier contient les mots à inclure dans notre programme. Si un des mots du fichier est dans les tags l'évènement est pris en compte sinon il est rejeté
mots_inclure = root+'/data/mots_a_inclure.txt'

with codecs.open(mots_inclure, mode="r", encoding="utf-8") as f:
	fichier_entier = f.read()
	files = fichier_entier.split("\n")

# Debut de la transaction
p = r.pipeline()

if r.exists("local_event_list") == 1:
    p.delete(*r.keys('local_event_list'))

p.execute()

# ----------ORLEANS------------#
log._logger.info("Traitement of open agenda metropole Orleans")

# Url contenant tous les évènements concernant la ville d'Orléans
try:
    url_orleans = config["URL"]["URL_O"]
except Exception as e:
    log._logger.error("Except error " +str(e))

# Appel de la checkUrl qui se trouve foaorleans.
# Cette fonction permet de vérifier si l'url renseignée est au bon format ou pas
if fonct_local_event.checkUrl(url_orleans):
    pass
else:
    log._logger.error("Program stopping because the url of Orleans is not in correct format or invalid")
    sys.exit(1)

fonct_local_event.iterQuery(url_orleans, offset, limit, today, files, timeLimitOrleans, r, p)

#--------------LOIRET-------------#
log._logger.info("Traitement of open agenda metropole Loiret")

# Url contenant tous les évènements concernant la ville de Loiret
try:
    url_loiret = config["URL"]["URL_L"]
except Exception as e:
    log._logger.error("Except error " +str(e))
    sys.exit(1)

# Appel de la checkUrl qui se trouve foaorleans.
# Cette fonction permet de vérifier si l'url renseignée est au bon format ou pas
if fonct_local_event.checkUrl(url_loiret):
    pass
else:
    log._logger.error("Program stopping because the url of Loiret is not in correct format or invalid")
    sys.exit(1)

fonct_local_event.iterQuery(url_loiret, offset, limit, today, files, timeLimitLoiret, r, p)

log._logger.info("End of the program")
log._logger.info("-----------------------------------------------------------------------------------------")
