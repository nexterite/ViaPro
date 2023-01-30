# coding: utf-8

# r.text          #Retourne le contenu en unicode
# r.content       #Retourne le contenu en bytes
# r.json          #Retourne le contenu sous forme json
# r.headers       #Retourne le headers sous forme de dictionnaire 
# r.status_code   #Retourne le status code

import requests
import os
import configparser
import io
import datetime
import codecs
import csv
import os.path
import sys
import dateparser
import log
import re
from os.path import basename

def headerCheck(url, root):

	name = basename(sys.argv[0])
	fileName, fileExtension = os.path.splitext(name)
	
	output = root+'/log/last_read/last_'+fileName+'.csv'

	x = datetime.datetime.now()

	date = x.strftime("%a, %d %b %Y %H:%M:%S GMT")  

	#print ('Je suis appelé')

	#Récupération de l'entête
	r = requests.head(url)

	#Récupération de l'entête sous la forme d'un dictionnaire
	data = r.headers

	# print data
 
	if os.path.exists(output) == False:
		with open(output, 'w+') as csvfile:	
			writer = csv.DictWriter(csvfile, fieldnames = ["Date", "file_name"])
			writer.writeheader()
			writer.writerow({'Date': date, 'file_name': fileName})
	else:
		i = 0		
		with open(output, "a+") as csvfile:
			reader = csv.DictReader(csvfile)
			for row in reader:
				if row['file_name'] == fileName:
					i = i + 1
			#print i

			if i == 0:
				writer = csv.DictWriter(csvfile, fieldnames = ["Date", "file_name"])
				writer.writerow({'Date': date, 'file_name': fileName})

			if i > 0:
				trouve = False
				for key, value in data.items():
					if key == "last-modified" or key == "date":
						last_date = dateparser.parse(value)
						with open(output, "a+") as csvfile:
							reader = csv.DictReader(csvfile)
							for row in reader:			
								api_date = dateparser.parse(row['Date'])
								if (api_date == last_date and row['file_name'] == fileName) or (api_date > last_date and row['file_name'] == fileName):
	#								print ("Je sors")
									log._logger.info("The program stops because the file has not been updated since the last execution")	
									log._logger.info("End of the program "+fileName)
									log._logger.info("-----------------------------------------------------------------------------------------------")
									sys.exit()
								else:
									trouve = True
							if trouve == True:
								writer = csv.DictWriter(csvfile, fieldnames = ["Date", "file_name"])
								writer.writerow({'Date': value, 'file_name': fileName})
