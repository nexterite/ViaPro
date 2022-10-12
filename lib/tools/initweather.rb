require 'json'
require 'date'
require 'logger'
require 'redis'
require "psych"
#
#  This programm creates the cities hash containing
#  the coordinates for every city in Loiret department that
#  can get current weather conditions with www.openweathermap.org
#
#  For simplicity it takes the coordinates as provided by the site itself
#

#
# Checking environment
#
    root = ENV["BEGOOD_PATH"]
    if root == nil then
         puts "Critical error with rufus, missing BEGOOD_PATH"
         exit 1
    end
#
# Set common variables and init global structures
#
    bindir    = "#{root}/bin"
    initdir   = "#{root}/init"
    logdir    = "#{root}/log"
    datadir   = "#{root}/data"
    citiesfile = "#{datadir}/cities.yml}"

    redis = Redis.new(host: "localhost", port: 6379, db: 0)

    r = redis.hgetall('current-weather')
    if r.empty? == true then
        puts "current-weather hash is empty"
        exit
    end
    coord = Hash.new()
    r.each { |key,value|
        det = JSON.parse(value)
        next if key == nil
        next if key.length == 0
        next if value.empty? == true
        lat = det["coord"]["lat"]
        long = det["coord"]["lon"]
        coord[key] = [ lat.to_f, long.to_f ]
#       puts "key=#{key}\nlat=#{det["coord"]["lat"]} long=#{det["coord"]["lon"]}"
    }
    File.open(cities , "w") { |f|
        Psych.dump(coord, f)
    }
