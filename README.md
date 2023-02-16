**Prerequisites**

ViaPro was created under Ubuntu 16.04 but can run without problems on Ubuntu 18.04 or 20.04. It uses Redis (standard 4.0.6 but we prefer the more recent 6.2.6 version) to store the data, Puma (version 4.3.6 or higher), Sinatra (version 2.1.0 or higher) and Rack (version 2.2.3 or higher) to manage http requests.

Python 3.8 is used.

The programs use a certain number of external modules that must be installed prior to any attempt to run ViaPro.

Ruby programs require rufus-scheduler, sinatra, redis, securerandom and geokit modules. Please use gem to install the modules.
For Python the file requirements38.txt under lib/collector list the required modules. Please use pip install command to install them.

Make sure all software requirements are fulfilled and are running (Redis and Puma ) before starting ViaPro.

**Installation**

 - Create a new user environment, user name project for example. 
 - Modify  your .bashrc file and add at the end the following line:
 export  BEGOOD_PATH=/home/viapro 
 - where/home/viapro is user project home  directory
 - Clone current project structure in Backend directory.
 - Create the following directories: Backend/log, Backend/log/puma, Backend/log/rufus,   Backend/log/collector and Backend/log/last_read

**ViaPro structure**

The current version holds the following directory structure:

-   bin - running shell commands
-   lib - source libraries
-   init - init files for programs
-   data - data files for collector programs
-   setup - Nginx configuration files examples

Under the lib directory:
- lib/rufus contain the programs that keep the backend up and ready: referee, scheduler, delete and dataclener. They are running continuously.
- lib/sinatra contains Sinatra application and configuration programs
- lib/collector contains the data collectors programs. A data collector is a program that periodically read a data source, convert it and push it to the local Redis database.

Collectors are run by scheduler at defined intervals. Look into scheduler.rb to find details. Collectors take specific configuration parameters from corresponding init file and if needed data from data directory.
Processed data is stored into Redis database. 
Http incoming calls will be processed within app.rb under lib/sinatra. Result is sent back as an object in json format.

**Configuration**

ViaPro use the following parameters :
- Redis (on localhost, listen to port 6379 and database 0 ), 
- Puma (listening on socket unix:///tmp/pumaproject.sock) and 
- Sinatra (called from Puma using rackup configuration file rackup config.ru). 
As you need a Web server we provide a Nginx configuration example that use port 9800 to listen for local http connections to Puma and port 443 for external https connections. You must adapt domain name and certificates to adapt to your local needs (see viapro.conf and nginx.conf files user setup/system/nginx). 

All programs use the applications default values, nothing should be changed.

Fo testing pourpose, choose one of the collectors sitting in lib/collector directory.
Current weather ( cweather.py ) it's one easy to configure and test. 
It connects to api.openweathermap.org/data/2.5/weather to download meteo data. Register to the site and take an application id ( appid ). Then set the URL entries in cweather.ini file. Finally, adapt scheduler.rb program to launch only this collector, comments all the others calls.

**Runtime**

Go to bin and execute startcollector shell script. 
  $ startcollector
The collector programms will be executed at defined intervals. 
Execute startpuma shell script to start Puma and Sinatra.
  $ startpuma
Or install puma.service as a system service
  $ cd /home/project/Backend/bin
  $ sudo cp puma.service /etc/systemd/system/puma.service
  $ sudo cp puma.service /lib/systemd/system/puma.service
  $ sudo systemctl enabled puma
  $ sudo systemctl --system daemon-reload
Then start the service
  $ sudo systemctl start puma

To check everything is fine execute dump.rb program at lib/tools to download the collected weather data from local database.
 ( if you changed network parameters please modify url parameters in dump.rb)
  $ ruby dump.rb

Another usefull program is tsinatra.rb that will call all ViaPro REST interface entries. It's a good example of what can be done with the interface. Run like
  $ ruby tsinatra.rb
 ( if you changed network parameters please modify url parameters in tsinatra.rb)

Use stopcollector to stop the backend programs and stoppuma to stop Puma ( or stop puma service with systemctl command)
