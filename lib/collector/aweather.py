# -*- coding: utf-8 -*-

import zipfile
import json
import codecs
import urllib
import io
import os
import ConfigParser
from lxml import etree
import locale
from datetime import datetime, timedelta
import xml.etree.ElementTree as ET
import log
import time
import sys
import httplib
from urlparse import urlparse
import header
import redis
import csv, unicodecsv

log._logger.info("Start of the program for the alerts weather")

# Connexion au serveur redis
c = redis.ConnectionPool(host='127.0.0.1', port='6379', db=0, decode_responses=True)
r = redis.StrictRedis(connection_pool=c)

def checkUrl(url):
    p = urlparse(url)
    conn = httplib.HTTPConnection(p.netloc)
    conn.request('HEAD', p.path)
    resp = conn.getresponse()
    return resp.status < 400

root = os.environ.get('BEGOOD_PATH')
root_version = os.environ.get('BEGOOD_VERSION')

if root:
    pass
else:
    log._logger.error("The environment variable entered does not exist")
    sys.exit()

conf = root+'/init/aweather.ini'


with codecs.open(conf) as f1:
    sample_config = f1.read()


config = ConfigParser.RawConfigParser(allow_no_value=True)
config.readfp(io.BytesIO(sample_config))

url = config.get("URL", "url")

if checkUrl(url):
    log._logger.debug("Check if the url is in a good format and that the browser does not generate an error")
    log._logger.debug("If ok, the program continu")
    pass
else:
    log._logger.error("Program stopping because the url is not in correct format or invalid")
    sys.exit()

header.headerCheck(url, root)

try: 
    os.makedirs("/tmp/"+root_version)
except OSError:
    if not os.path.isdir("/tmp/"+root_version):
        raise

log._logger.debug("Retrieving the downloaded zip file in /tmp/vigilance.zip")

urllib.urlretrieve(url, "/tmp/"+root_version+"/vigilance"+str(os.getpid())+".zip")

log._logger.debug("Reading of the zip file")
zip_ref = zipfile.ZipFile("/tmp/"+root_version+"/vigilance"+str(os.getpid())+".zip", "r")

log._logger.debug("Extracting of the zip file in the directory /tmp/alerts")
zip_ref.extractall("/tmp/"+root_version+"/alerts")

log._logger.debug("Reading of the file concerning weather informations locate in /tmp/alerts/NXFR33_LFPW_.xml")
meteo = etree.parse("/tmp/"+root_version+"/alerts/NXFR33_LFPW_.xml")

log._logger.debug("Reading of the file concerning weather informations locate in /tmp/alerts/NXFR34_LFPW_.xml")
crue = etree.parse("/tmp/"+root_version+"/alerts/NXFR34_LFPW_.xml")

zipper = "/tmp/"+root_version+"/vigilance"+str(os.getpid())+".zip"

os.remove(zipper)

root_meteo = meteo.getroot()

root_crue = crue.getroot()

log._logger.debug("Creating dictionaries to retrieve file information.")
log._logger.debug("These dictionaries will be used to create our json output file.")

log._logger.debug("NXFR33_LFPW_.xml file path")

# Debut de le transaction
p = r.pipeline()
if r.exists("alerts-weather") == 1:
    p.delete(*r.keys('alerts-weather'))

i = 1

log._logger.debug("NXFR33_LFPW_.xml file path")
date_string = ""
for file in root_meteo:
    if file.tag == "EV":
        date = file.get('dateinsert')
        date_string = date[0:4]+"-"+date[4:6]+"-"+date[6:8]+" "+date[8:10]+":"+date[10:12]+":"+date[12:14]
    dico = {}
    dico['risk types'] = []
    if '45' == file.get('dep'):
        if file.get('coul') == '1':
            log._logger.debug("Retrieving the 'risque' value for department of Loiret if the value is equal to 1")
            dico['risk level'] = '1'
            dico['region'] = "45"
            dico['time'] = date_string
            dico['risk types'].append('None')
            
            p.hset("alerts-weather", i, json.dumps(dico, ensure_ascii=False).encode('utf-8'))

            i = i + 1
        else:
            for node in file.findall('risque'):
                dico['risk types'].append(node.get('val'))
                dico['region'] = "45"
                dico['time'] = date_string
                dico['risk level'] = file.get('coul')
            taille = len(dico['risk type'])
            if taille == 1:
                for node in file.findall('risque'):
                    #On écrase la liste dico['risk type']
                    dico['risk type'] = node.get('val')
                    with open(root+"/data/weather-alerts-codes.csv") as csvfile:
                        reader = csv.DictReader(csvfile)
                        for row in reader:
                            if row['code'] == node.get('val'):
                                dico['risk message'] = {}
                                dico['risk message']['fr'] = row['title FR']
                                dico['risk message']['en'] = row['title EN']
                p.hset("alerts-weather", i, json.dumps(dico, ensure_ascii=False).encode('utf-8'))

                i = i + 1
            else:
                dico['risk messages'] = []
                for node in file.findall('risque'):
                    with open(root+"/data/weather-alerts-codes.csv") as csvfile:
                        reader = csv.DictReader(csvfile)
                        for row in reader:
                            if row['code'] == node.get('val'):
                                data = {}
                                data['en'] = row['title EN']
                                data['fr'] = row['title FR']
                                dico['risk messages'].append(data)
                p.hset("alerts-weather", i, json.dumps(dico, ensure_ascii=False).encode('utf-8'))

                i = i + 1                       


#Execution et fin de la transaction
p.execute()

log._logger.info("End of the program")
log._logger.info("-----------------------------------------------------------------------------------------")
