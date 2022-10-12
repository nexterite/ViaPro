# coding: utf-8

import calendar
from datetime import date, timedelta, datetime
import csv
import time

def convertTimeNow(today):
    x1 = time.strptime(today.split(',')[0],'%H:%M:%S')
    itv1 = timedelta(hours=x1.tm_hour,minutes=x1.tm_min,seconds=x1.tm_sec).total_seconds()
    return itv1


def sunday(year, month):
# January 1st of the given year
       dt = date(year, month, 1)
# First Sunday of the given year    
       dt += timedelta(days = 6 - dt.weekday())
       return dt
       # while dt.month == month:
       #    yield dt
       #    dt += timedelta(days = 7)
          
# for s in all_sundays(2019, 5):
#    print(s)

#
# add market id as unique identifier number
#
def addToDict(dico, row, location, duration, now, marketid):
	location['latitude'] = row['Latitude']
	location['longitude'] = row['Longitude']
	dico['geolocation'] = location
	dico['unique disruption number'] =  marketid
	dico['disruption type'] = "market"
	dico['direction'] = "nil"
	dico['severity level'] = 1 
	dico['address'] = row['adresse']+", "+row['Ville']
	dico['planned start date'] = "nil"
	dico['planned end date'] = "nil"
	dico['actual start date'] = now[0:10]+" "+row['heure debut']
	dico['actual end date'] = now[0:10]+" "+row['heure fin']
	dico['planned duration'] = str(duration)
	dico['source'] = "Market file"
	if row['commentaire'] == "":
		dico['short description'] = "nil"
	else:
		dico['short description'] = row["commentaire"]
	dico['detailed description'] = "nil"
	dico['picture'] = 'nil'
	dico['public description'] = 'nil'
	dico['private description'] = 'nil'

def timeDifference(row, time_now):
	heure = datetime.strptime(row['heure debut'], "%H:%M")
	heure2 = datetime.strptime(row['heure fin'], "%H:%M")
	duration = heure2 - heure
	heure_convert = heure.strftime("%d/%m/%Y %H:%M:%S")
	time_start_event = convertTimeNow(heure_convert[11:19])
	diff = time_now - time_start_event
	return diff, duration
