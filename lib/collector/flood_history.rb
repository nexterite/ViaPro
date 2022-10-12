require 'json'
require 'logger'
require 'redis'
#
# BEGOOD - Flood history
#
    root = ENV["BEGOOD_PATH"]
    if root == nil then
         puts "Critical error with cwflood_history, missing BEGOOD_PATH"
         exit 1
    end

    logdir   = "#{root}/log"
    logfile  = "#{logdir}/app.log"
    initdir  = "#{root}/init"
    datadir  = "#{root}/data"
    initfile = "#{initdir}/flood_history.ini"
    generalfile  = "#{initdir}/general.ini"
#
#   Initialization
#
    general = Hash.new()
    if File.exist?(generalfile) == true then
        File.open(generalfile, 'r') { |f|
            f.each_line { |line|
                l = line.chomp.split('=')
                general[l[0]] = l[1]
            }
        }
    end
    file = File.new(logfile, 'a+')
    file.sync = true
    logger = Logger.new(file)
    if general.has_key?('Log_level') == true then
        logger.level = general['Log_level']
    else
        logger.level = 'ERROR'
    end
    logger.info('Flood history') { "Flood history collector called at #{Time.now}" }
#
# Set common variables
#
    area = nil
    pdate = nil
    fname = nil
    if File.exist?(initfile) == true then
        File.open(initfile, 'r') { |f|
            f.each_line { |line|
                l = line.chomp!.split('=')
                case l[0]
                    when 'area'
                        area = l[1]
                    when 'pdate'
                        pdate = l[1]
                    when 'fname'
                        fname = "#{datadir}/#{l[1]}"
                        if File.exist?(fname) == false then
                            logger.error('flood_history') { "data file #{fname} doesn't exist" }
                            exit
                        end
                    else
                        logger.error('flood_history') { "Initfile #{initfile} contain unknown option #{l[0]} " }
                end
            }
        }
        if  area == nil then
            logger.fatal('flood_history') { "Parameter area is missing in Initfile #{initfile}" }
            exit
        end
        if  pdate == nil then
            logger.fatal('flood_history') { "Parameter pdate is missing in Initfile #{initfile}" }
            exit
        end
        if  fname == nil then
            logger.fatal('flood_history') { "Parameter fname is missing in Initfile #{initfile}" }
            exit
        end
    else
        logger.fatal('flood_history') { "Initfile #{initfile} is missing " }
        exit
    end

    file = File.open(fname, 'r')
    geojson = file.read
    fhistory = { "area name" => area, "publication date" => pdate, "geojson" => geojson}
    require 'redis'
    
    redis = Redis.new(host: "localhost", port: 6379, db: 0)
    logger.debug('flood_history') { "Redis connected" }
    
    redis.multi do
        redis.del("flood_history")
        redis.hset("flood_history", 1, fhistory.to_json)
    end
    logger.debug('flood_history') { "Redis disconnected" }
