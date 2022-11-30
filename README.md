Prerequisites

ViaPro was created under Ubuntu 16.04 but can run without problems on Ubuntu 18.04 or 20.04.
It uses Redis (standard 4.0.6 but we prefer the more recent 6.2.6 version) to store the data, Puma (version 4.3.6 or later) and Sinatra (version   2.1.0 or later)  ad Rack (version 2.2.3 or later to manage http requests.

Ruby version is 2.7.0 but the programs should run without problems on any superior version.
Python 2.7 was originally used using Python 3.6 or Python 3.8 will require minor changes.

The programs use a certain number of external modules that must be installed prior to any attempt to run ViaPro.

Ruby programs require rufus-scheduler, sinatra, redis, securerandom and geokit modules. Please use gem to install the modules.
For Python the file requirements.txt under lib/collector list the required modules. Please use pip install command to install them.
 
Please make sure all software requirements are fulfilled and are running (Redis and Puma ) before starting ViaPro.

Installation

- Create a new user environment, user name project for example.
- Modify your .bashrc file and add at the end the following line:
export BEGOOD_PATH=/home/project
where/home/project is user project home directory.
- Clone current project structure under your home directory.
- Create the following directories: log, log/puma, log/rufus, log/collector and log/last_read

Structure

The current version holds the following directory structure:
- bin - running shell commands
- lib - source libraries
- init - init files for programs
- data - data files for collector programs

lib/rufus holds the programs keeps the backend up and ready: referee, scheduler, delete and dataclener.They are running continuously
lib/sinatra holds Sinatra application
lib/collector holds the data collector program. A data collector is a program that periodically read a data source, convert it and push it to the local Redis database.

A collector is run by the scheduler at intervals defined into the program, takes its parameters from input from the corresponding init file and data from data directory, if needed. Collected data arrives into Redis.
All http calls will arrive at app.rb under lib/sinatra , calls will be processed, data taken from Redis structures and send back to  calling client as an object in json format.

Configuration

ViaPro use the default parameters for Redis (on localhost, listen to port 6379 and database 0 ), Puma (listening on port 9292) and Sinatra (listening on port 4567).
All programs use the default value, nothing should be changed.

Browse  the collector directory directory and choose one of the collectors you want to  test.
Current weather ( cweather.py ) seem to easiest to test. It connects to api.openweathermap.org/data/2.5/weather to  download meteo data. Register to the site and take an application id ( appid ). Then fill these information in init/cweather.ini file
Finally, adapat scheduler.rb program to launch only this collector, comments all the others.

Running

Go to bin and execute startcollector shell script. The collector will be executed at defined intervals.
Execute startpuma shell script. This will start Puma and Sinatra.
Go to lib/tools and run dump.rb program to download weather data frol local database.

Stopcollector stops the backend programs
Stoppuma stops Puma
  
