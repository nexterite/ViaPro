# coding: utf-8

import time
from datetime import timedelta
import requests
import log
import logging
import codecs
import sys
import os
import io
import ConfigParser
from urlparse import urlparse
import httplib
import json
import dateparser
import header

root = os.environ.get('BEGOOD_PATH')

def convertTimeStart(elt):
    x = time.strptime(elt.split(',')[0],'%H:%M:%S')
    itv = timedelta(hours=x.tm_hour,minutes=x.tm_min,seconds=x.tm_sec).total_seconds()
    return itv

def convertTimeNow(today):
    x1 = time.strptime(today.split(',')[0],'%H:%M:%S')
    itv1 = timedelta(hours=x1.tm_hour,minutes=x1.tm_min,seconds=x1.tm_sec).total_seconds()
    return itv1

def addInfoDict(data, today, files, timeLimit):
    dico2 = {}
    dico2['Events'] = []
    for key, value in data.items():
        if key == 'events':
            if isinstance(value, list):
                for element in value:
                    if isinstance(element, dict):
                        for sub_key, sub_value in element.items():
                            if sub_key == 'timings':
                                if isinstance(sub_value, list):
                                    for elt in sub_value:
                                        if isinstance(elt, dict):
                                            if (today[0:10] >= elt['start'][0:10] and today[0:10] <= elt['end'][0:10]):
                                                dico = {}

                                                itv = convertTimeStart(elt['start'][11:19])
                                                itv1 = convertTimeNow(today[11:19])

                                                for elts in element['tags']:
                                                    tab = elts['label'].split(' - ')
                                                
                                                titre = ""
                                                for cle, valeur in element['title'].items():
                                                    if cle == "fr":
                                                        titre = valeur.encode('utf-8')
                                                    else:
                                                        titre = valeur.encode('utf-8')

                                                if abs((itv1 - itv)) > timeLimit:
                                                    pass
                                                else:
                                                    for word in files:
                                                        for mot in tab:
                                                            locations = {}
                                                            mot1 = u''.join(word).encode('utf-8').strip()
                                                            mot2 = u''.join(mot).encode('utf-8').strip()
                                                            if mot1.lower() == mot2.lower() or mot1.lower() in titre.lower():
                                                                dico['unique disruption number'] = element['uid']
                                                                dico['disruption type'] = "local event" 
                                                                locations['latitude'] = element['latitude']
                                                                locations['longitude'] = element['longitude']
                                                                dico['geolocation'] = locations
                                                                dico['direction'] = "nil"
                                                                dico['severity level'] = 1
                                                                dico['visibility'] = 'yes'
                                                                dico['address'] = element['address']
                                                                dico['planned start date'] = element['firstDate']+" "+element['firstTimeStart']
                                                                dico['planned end date'] = element['lastDate']+" "+element['firstTimeEnd']
                                                                date_start = dateparser.parse(elt['start'])
                                                                date_end = dateparser.parse(elt['end'])
                                                                dico['actual start date'] = str(date_start)
                                                                dico['actual end date'] = str(date_end) 
                                                                dico['planned duration'] = str(date_end - date_start)
                                                                dico['source'] = 'Open Agenda'
                                                                if element['description'] == None:
                                                                    dico['short description'] = "nil"
                                                                else:
                                                                    for cle, valeur in element['description'].items():
                                                                        if cle == 'fr':
                                                                            description = valeur.replace("/"," ")
                                                                            dico['short description'] = description

                                                                for cle, valeur in element['title'].items():
                                                                    if cle == "fr":
                                                                        dico['detailed description'] = valeur
                                                                    else:
                                                                        dico['detailed description'] = valeur

                                                                dico['picture'] = 'nil'
                                                                dico['public description'] = 'nil'
                                                                dico['private description'] = 'nil'
                                                                dico2['Events'].append(dico)
    return dico2

def checkUrl(url):
    p = urlparse(url)
    conn = httplib.HTTPConnection(p.netloc)
    conn.request('HEAD', p.path)
    resp = conn.getresponse()   
    return resp.status < 400

def addTransactionRedis(dico, redi, pipe):
    for value in dico.items():
        if isinstance(value, list):
            for element in value:
                pipe.lpush("local_event_list", json.dumps(element, ensure_ascii=False).encode('utf-8'))
                pipe.execute()

def iterQuery(url, offset, limit, today, files, timeLimit, r, p):
    trouve = True

    while trouve:
        # Stockage de l'url dans la variable query
        query = url + "offset="+str(offset)+"&limit="+str(limit)

        if offset == 300:
            break
            
        header.headerCheck(query, root)

        try:
            # Exécution de l'url
            content = requests.get(query)
            # On precise à python que les données recupérées sont au format json
            data = content.json()
        except Exception as e:
            log._logger.error("Except error " +str(e))
            sys.exit(1)

        log._logger.info("with the url "+query)

        # Appel de la addInfoDict qui se trouve dans le foaorleans.
        # Cette focntion parcourt la variable data déclarée préablement, récupere la date du jour, le dictionnaire de stockage et la valeur timeLimitOrleans
        # Dans cette fonction sont verifiés : le résultat de la difference entre la du jour et le dernier paramètre de la fonction,
        # , si les mots à inclure correspondent à ceux de nos champs dans data, enfin tous les champs stockes dans new_data sont mis dans la liste new_data["events"]
        dico = {}
        dico = addInfoDict(data, today, files, timeLimit)
        addTransactionRedis(dico, r, p)
        offset = offset + 100
        limit = limit + 100
        for key, value in data.items():
            if key == "events":
                if len(value) == 0:
                    trouve = False
