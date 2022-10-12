require 'json'
require 'date'
require 'logger'
require 'redis'
require 'time'

    disruptions = {
    'cweather'           => {"rediskey" =>"current-weather",               "time_control" => "no"},
    'fweather'           => {"rediskey" =>"forecast-weather",              "time_control" => "no"},
    'aweather'           => {"rediskey" =>"alerts-weather",                "time_control" => "no"},
    'aquality'           => {"rediskey" =>"air-quality",                   "time_control" => "no"},
    'gstation'           => {"rediskey" =>"gstation",                      "time_control" => "no"},
    'careas'             => {"rediskey" =>"carpool",                       "time_control" => "no"},
    'bparking'           => {"rediskey" =>"bparking",                      "time_control" => "no"},
    'parking'            => {"rediskey" =>"parking",                       "time_control" => "no"},
    'jams'               => {"rediskey" =>"jams",                          "time_control" => "no"},
    'risk_areas'         => {"rediskey" =>"risk_areas",                    "time_control" => "no"},
    'flood_history'      => {"rediskey" =>"flood_history",                 "time_control" => "no"},
    'roadworks'          => {"rediskey" =>"disruption:roadworks",          "time_control" => "yes"},
    'roadclosure'        => {"rediskey" =>"disruption:roadclosure",        "time_control" => "yes"},
    'traffic_jam'        => {"rediskey" =>"disruption:traffic_jam",        "time_control" => "yes"},
    'flood'              => {"rediskey" =>"disruption:flood",              "time_control" => "yes"},
    'accident'           => {"rediskey" =>"disruption:accident",           "time_control" => "yes"},
    'animal'             => {"rediskey" =>"disruption:animal",             "time_control" => "yes"},
    'hazard'             => {"rediskey" =>"disruption:hazard",             "time_control" => "yes"},
    'serious_hazard'     => {"rediskey" =>"disruption:serious_hazard",     "time_control" => "yes"},
    'landslide'          => {"rediskey" =>"disruption:landslide",          "time_control" => "yes"},
    'technological_risk' => {"rediskey" =>"disruption:technological_risk", "time_control" => "yes"},
    'attack'             => {"rediskey" =>"disruption:attack",             "time_control" => "yes"},
    'market'             => {"rediskey" =>"disruption:market",             "time_control" => "yes"},
    'local_event'        => {"rediskey" =>"disruption:local_event",        "time_control" => "yes"}
    }

   root = ENV["BEGOOD_PATH"]
    if root == nil then
         puts "Critical error with dataclener.rb, missing BEGOOD_PATH"
         exit 1
    end
#
#   Set common variables
#
    logdir       = "#{root}/log"
    logfile      = "#{logdir}/app.log"
    initdir      = "#{root}/init"
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
    logger.info('datacleaner') { "datacleaner agent called at #{Time.now}" }
    redis = Redis.new(host: "localhost", port: 6379, db: 0)
    logger.info('datacleaner') { "Redis connected" }

    logger.info('datacleaner') { "1st step - validate entries in Redis" }
    disruptions.each { |key,value|
        r = redis.hkeys(value["rediskey"])
        if (r == nil) || (r.length == 0 ) then
            case key
                when 'cweather','fweather','aweather','aquality','gstation','careas','bparking,','parking','risk_areas','flood_history'
                    logger.error('datacleaner') { "#{key} shouldn't be empty in Redis database"}
                when 'landslide','technological_risk','flood','attack'
                    logger.info('datacleaner') { "empty entry for #{key} is a normal situation"}
                when 'roadworks','roadclosure'
                    logger.error('datacleaner') { "#{key} shouldn't be empty in Redis database"}
                when 'jams','traffic_jam','accident','animal','hazard','serious_hazard','market','local_event'
                    logger.info('datacleaner') { "#{key} with no entries may be a normal situation"}
                else
                    logger.error('datacleaner') { "Unknown key=#{key}"}
            end
        else
            logger.error('datacleaner') { "#{key} has #{r.length} entries"}
        end
    }

    logger.info('datacleaner') { "2nd step - validate entries with time values in Redis"}
    run_time = Time.now()
    delayed = 0

    disruptions.each { |key,value|

        next if value["time_control"] == 'no'

        r = redis.hkeys(value["rediskey"])
        next if (r == nil) || (r.length == 0 )

        logger.info('datacleaner') { "#{key} has #{r.length} entries"}
        r.each { |id|
            k = redis.hget(value["rediskey"], id)
            case key
                when 'roadworks','roadclosure','traffic_jam','flood','accident','animal','hazard','serious_hazard','landslide','technological_risk','attack','market','local_event'
                    body = JSON.parse(k)
                    if body.has_key?("actual end date") then
                        limit = body["actual end date"]
                    elsif body.has_key?("planned end date") then
                        limit = body["planned end date"]
                    else
                        logger.error('datacleaner') { "Big issue, no end date for #{body}" }
                        next
                    end
                    t = Time.parse( limit )
                    next if t > run_time                               # end date is in the future
                    if (run_time - t) < 5 then
                        logger.info('datacleaner') {"short_term event #{body}" }
                    end
                    x = redis.hdel(value["rediskey"], id)
                    if x.to_i == 1 then
                        logger.error('datacleaner') { "key = #{id} in #{key} deleted" }
                    else
                        logger.error('datacleaner') { "issue when deleting key #{id}" }
                    end
                    delayed += 1
                    logger.error('datacleaner') { "we deleted in #{key} with key=#{id} the entry #{body}" }
                else
                    logger.error('datacleaner') { "Unknown key=#{key} value=#{k}" }
            end
        }
        logger.error('datacleaner') { "#{delayed} entries deleted in this execution" } if delayed != 0
    }
