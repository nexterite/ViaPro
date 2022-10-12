# coding: utf-8

from datetime import date, timedelta, datetime
import os
import csv
import time
import log
import redis
import fonct_market
import json
import codecs
import datetime

log._logger.info("Start of the program for Local-event")

root  = os.environ.get('BEGOOD_PATH')

# Connexion au serveur redis
c = redis.ConnectionPool(host='127.0.0.1', port='6379', db=0,)
r = redis.StrictRedis(connection_pool=c)

date_now = datetime.datetime.now()

timeLimit = 14400

format = "%d/%m/%Y %H:%M:%S"
now = date_now.strftime(format)
time_now = fonct_market.convertTimeNow(now[11:19])

sunday = fonct_market.sunday(date_now.year, date_now.month)

csv1 = root+'/data/jours_feries_2019-2020-2021.csv'
csv2 = root+'/data/Marches_reguliers_geolocalises_2019-05-22.csv'

str_sunday = sunday.strftime(format)

# Debut de la transaction
p = r.pipeline()
if r.exists("market_list") == 1:
    p.delete(*r.keys('market_list'))

i = 1

json_string = ""

with open(csv2) as csvfile, codecs.open(csv1) as csvfile1:
	reader = csv.DictReader(csvfile)
	for row in reader:
		if isinstance(row, dict):
			for key, value in row.items():
				if key == "jour de la semaine" and value == "lundi" and date_now.weekday() == 0:
					diff, duration = fonct_market.timeDifference(row, time_now)
					if abs(diff) > timeLimit:
						pass
					else:
						dico = {}
						location = {}
						
						fonct_market.addToDict(dico, row, location, duration, now, "Market "+str(i))

						json_string = str(dico)

						p.lpush("market_list", json.dumps(dico, ensure_ascii=False))

						i = i + 1
				if key == "jour de la semaine" and value == "mardi" and date_now.weekday() == 1:
					diff, duration = fonct_market.timeDifference(row, time_now)
					if abs(diff) > timeLimit:
						pass
					else:
						dico = {}
						location = {}

						fonct_market.addToDict(dico, row, location, duration, now, "Market "+str(i))

						json_string = str(dico)

						p.lpush("market_list", json.dumps(dico, ensure_ascii=False))

						i = i + 1 

				if key == "jour de la semaine" and value == "mercredi" and date_now.weekday() == 2:
					diff, duration = fonct_market.timeDifference(row, time_now)
					if abs(diff) > timeLimit:
						pass
					else:
						dico = {}
						location = {}						
						
						fonct_market.addToDict(dico, row, location, duration, now, "Market "+str(i))

						json_string = str(dico)

						p.lpush("market_list", json.dumps(dico, ensure_ascii=False))

						i = i + 1

				if key == "jour de la semaine" and value == "jeudi" and date_now.weekday() == 3:
					diff, duration = fonct_market.timeDifference(row, time_now)
					if abs(diff) > timeLimit:
						pass
					else:
						dico = {}
						location = {}

						fonct_market.addToDict(dico, row, location, duration, now, "Market "+str(i))

						json_string = str(dico)
						
						p.lpush("market_list", json.dumps(dico, ensure_ascii=False))

						i = i + 1
				if key == "jour de la semaine" and value == "vendredi" and date_now.weekday() == 4:
					diff, duration = fonct_market.timeDifference(row, time_now)
					if abs(diff) > timeLimit:
						pass
					else:
						dico = {}
						location = {}

						fonct_market.addToDict(dico, row, location, duration, now, "Market "+str(i))

						json_string = str(dico)

						p.lpush("market_list", json.dumps(dico, ensure_ascii=False))

						i = i + 1
				if key == "jour de la semaine" and value == "samedi" and date_now.weekday() == 5:
					diff, duration = fonct_market.timeDifference(row, time_now)
					if abs(diff) > timeLimit:
						pass
					else:
						dico = {}
						location = {}

						fonct_market.addToDict(dico, row, location, duration, now, "Market "+str(i))

						json_string = str(dico)

						p.lpush("market_list", json.dumps(dico, ensure_ascii=False))

						i = i + 1
				if key == "jour de la semaine" and value == "dimanche" and date_now.weekday() == 6:
					diff, duration = fonct_market.timeDifference(row, time_now)
					if abs(diff) > timeLimit:
						pass
					else:
						dico = {}
						location = {}

						fonct_market.addToDict(dico, row, location, duration, now, "Market "+str(i))

						json_string = str(dico)

						p.lpush("market_list", json.dumps(dico, ensure_ascii=False))

						i = i + 1
				if key == "jour de la semaine" and value == "jours fériés":
					reader1 = csv.DictReader(csvfile1)
					for row1 in reader1:
						for key1, value1 in row1.items():
							if key1 == "date" and value1 in now:
								diff, duration = fonct_market.timeDifference(row, time_now)
								if abs(diff) > timeLimit:
									pass
								else:
									dico = {}
									location = {}

									fonct_market.addToDict(dico, row, location, duration, now, "Market "+str(i))

									json_string = str(dico)

									p.lpush("market_list", json.dumps(dico, ensure_ascii=False))

									i = i + 1
				if key == "jour de la semaine" and value == "1er dimanche du mois" and str_sunday in now:
					diff, duration = fonct_market.timeDifference(row, time_now)
					if abs(diff) > timeLimit:
						pass
					else:
						dico = {}
						location = {}
						
						fonct_market.addToDict(dico, row, location, duration, now, "Market "+str(i))

						json_string = str(dico)

						p.lpush("market_list", json.dumps(dico, ensure_ascii=False))
						
						i = i + 1

# Execution et fin de la transaction
p.execute()

log._logger.info("End of the program")
log._logger.info("-----------------------------------------------------------------------------------------")