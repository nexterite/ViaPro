require 'json'
require 'date'
require 'logger'
require 'redis'
require 'time'
#
# BEGOOD - Referee agent
#
# Main goal is to:
#
#  - take entries from various alerts lists and assign them to dedicated hashes
#  - deal with concurrent accesses to the same alert
#  - deal with alert proximities
#
#  - FOR INSERT or UPDATE tasks
#
    root = ENV["BEGOOD_PATH"]
    if root == nil then
         puts "Critical error with referee.rb, missing BEGOOD_PATH"
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

    logger.info('Referee') { "Referee agent called at #{Time.now}" }

    redis = Redis.new(host: "localhost", port: 6379, db: 0)
    logger.info('Referee') { "Redis connected" }

# 
#   Loop over disruption alerts lists and dispatch according to criterias
#
#   There is only 1 list par disruption type, name is object_list like accident_list
#   some lists may be empty
#   There are 13 different types of disruptions
#
while true

    begin
    r = redis.brpop('serious_hazard_list','accident_list','traffic_jam_list','hazard_list','roadwork_list','roadclosure_list','animal_list', 'flood_list', 'landslide_list', 'technological_risk_list', 'attack_list', 'market_list', 'local_event_list',60)
    rescue Interrupt
        logger.info('Referee') { "We got an interrupt and will immediately leave" }
        logger.close
        exit
    end 
    next if r == nil
    #
    # We got an alert
    #
    alert = JSON.parse(r[1])
    #
    # Check if it's an obsolete disruption
    #
    t1 = Time.parse( alert["planned end date"])
    t2 = Time.parse( alert["actual end date"])
    t0 = Time.now()
    if (t1 < t0) && (t2 < t0) then
        logger.info('referee') { "event #{alert} is obsolete, it was rejected" }
        next
    end 
    #
    # Main processing area
    #
    case r[0]
        when 'accident_list'
            #
            # ACCIDENTS
            #
            if alert["source"] == "Waze"  then                           # an accident coming from Waze
                #
                # we must loop thru current list of disruption:accident and check if this event exist or not
                #
                all = redis.hgetall('disruption:accident')
                found = false
                all.each { |key,value|
                    hc = JSON.parse(value)
                    if hc["unique disruption number"] == alert["unique disruption number"] then
                        found = true
                        redis.hset("disruption:accident", key, alert.to_json)
                        logger.debug('Referee') { "UPDATED accident\nhc=#{hc}\nalert=#{alert}" }
                        break
                    end
                }
                if found == false then                                   # create a new accident entry
                    id = redis.incr("accident-id")
                    redis.hset("disruption:accident", id, alert.to_json)
                    logger.debug('Referee') { "CREATED a new accident alert key=#{id} alert=#{alert}" }
                end
            else
                logger.error('Referee') { "Accident alert with type #{alert["source"]} not implemented yet\nalert=#{alert}" }
            end

        when 'hazard_list'
            #
            # HAZARDS
            #
            if alert["source"] == "Waze"  then                           # a hazard coming from Waze
                #
                # we must loop thru current list of disruption:hazard and check if this event exist or not
                #
                all = redis.hgetall('disruption:hazard')
                found = false
                all.each { |key,value|
                    hc = JSON.parse(value)
                    if hc["unique disruption number"] == alert["unique disruption number"] then
                        found = true
                        redis.hset("disruption:hazard", key, alert.to_json)
                        logger.debug('Referee') { "UPDATED hazard\nhc=#{hc}\nalert=#{alert}" }
                        break
                    end
                }
                if found == false then                                   # create a new hazard entry
                    id = redis.incr("hazard-id")
                    redis.hset("disruption:hazard", id, alert.to_json)
                    logger.debug('Referee') { "CREATED a new hazard key=#{id} alert=#{alert}" }
                end
            else
                logger.error('Referee') { "hazard alert with source #{alert["source"]} not implemented yet\nalert=#{alert}" }
            end
        when 'serious_hazard_list'
            #
            # SERIOUS HAZARD
            #
            if alert["source"] == "Waze"  then                           # a serious_hazard coming from Waze
                #
                # we must loop thru current list of disruption:serious_hazard and check if this event exist or not
                #
                all = redis.hgetall('disruption:serious_hazard')
                found = false
                all.each { |key,value|
                    hc = JSON.parse(value)
                    if hc["unique disruption number"] == alert["unique disruption number"] then
                        found = true
                        redis.hset("disruption:serious_hazard", key, alert.to_json)
                        logger.debug('Referee') { "UPDATED serious_hazard alert\nhc=#{hc}\nalert=#{alert}" }
                        break
                    end
                }
                if found == false then                                   # create a new serious_hazard entry
                    id = redis.incr("serious_hazard-id")
                    redis.hset("disruption:serious_hazard", id, alert.to_json)
                    logger.debug('Referee') { "CREATED a new serious_hazard key=#{id} alert=#{alert}" }
                end
            else
                logger.error('Referee') { "serious_hazard alert with source #{alert["source"]} not implemented yet\nalert=#{alert}" }
            end
        when 'animal_list'
            #
            # ANIMAL
            #
            if alert["source"] == "Waze"  then                           # an animal coming from Waze
                #
                # we must loop thru current list of disruption:animal and check if this event exist or not
                #
                all = redis.hgetall('disruption:animal')
                found = false
                all.each { |key,value|
                    hc = JSON.parse(value)
                    if hc["unique disruption number"] == alert["unique disruption number"] then
                        found = true
                        redis.hset("disruption:animal", key, alert.to_json)
                        logger.debug('Referee') { "UPDATED animal\nhc=#{hc}\nalert=#{alert}" }
                        break
                    end
                }
                if found == false then                                   # create a new animal entry
                    id = redis.incr("animal-id")
                    redis.hset("disruption:animal", id, alert.to_json)
                    logger.debug('Referee') { "CREATED a new animal key=#{id} alert=#{alert}" }
                end
            else
                logger.error('Referee') { "animal alert with source #{alert["source"]} not implemented\nalert=#{alert}" }
            end
        when 'traffic_jam_list'
            #
            # TRAFFIC JAM
            #
            if alert["source"] == "Waze"  then                           # a traffic_jam coming from Waze
                #
                # we must loop thru current list of disruption:traffic_jam and check if this event exist or not
                #
                all = redis.hgetall('disruption:traffic_jam')
                found = false
                all.each { |key,value|
                    hc = JSON.parse(value)
                    if hc["unique disruption number"] == alert["unique disruption number"] then
                        found = true
                        redis.hset("disruption:traffic_jam", key, alert.to_json)
                        logger.debug('Referee') { "UPDATED traffic_jam\nhc=#{hc}\nalert=#{alert}" }
                        break
                    end
                }
                if found == false then                                   # create a new traffic_jam entry
                    id = redis.incr("traffic_jam-id")
                    redis.hset("disruption:traffic_jam", id, alert.to_json)
                    logger.debug('Referee') { "CREATED a new traffic_jam key=#{id} alert=#{alert}" }
                end
            else
                logger.error('Referee') { "traffic_jam alert with source #{alert["source"]} not implemented\nalert=#{alert}" }
            end
        when 'roadwork_list'
            #
            # ROADWORKS
            #
            # we must loop thru current list of disruption:roadworks and check if this event exist or not
            # "Waze" and "CDLoiret" code may look identical but the logic may diverge in time
            #
            all = redis.hgetall('disruption:roadworks')
            found = false

            case alert["source"]
                when "Waze"
                    all.each { |key,value|
                        hc = JSON.parse(value)
                        if hc["unique disruption number"] == alert["unique disruption number"] then
                            found = true
                            redis.hset("disruption:roadworks", key, alert.to_json)
                            logger.debug('Referee') { "UPDATED roadworks\nhc=#{hc}\nalert=#{alert}" }
                            break
                        end
                    }
                    if found == false then                                   # create a new traffic_jam entry
                        id = redis.incr("roadworks-id")
                        redis.hset("disruption:roadworks", id, alert.to_json)
                        logger.debug('Referee') { "CREATED a new roadworks key=#{id} alert=#{alert}" }
                    end
                when "CDLoiret"
                    all.each { |key,value|
                        hc = JSON.parse(value)
                        if hc["unique disruption number"] == alert["unique disruption number"] then
                            found = true
                            redis.hset("disruption:roadworks", key, alert.to_json)
                            logger.debug('Referee') { "UPDATED roadworks\nhc=#{hc}\nalert=#{alert}" }
                            break
                        end
                    }
                    if found == false then                                   # create a new traffic_jam entry
                        id = redis.incr("roadworks-id")
                        redis.hset("disruption:roadworks", id, alert.to_json)
                        logger.debug('Referee') { "CREATED a new roadworks key=#{id} alert=#{alert}" }
                    end
                else
                    logger.error('Referee') { "roadworks alert with source #{alert["source"]} not implemented\nalert=#{alert}" }
            end
        when 'roadclosure_list'
            #
            # ROADCLOSURE
            #
            # we must loop thru current list of disruption:roadclosure and check if this event exist or not
            # "Waze" and "CDLoiret" code may look identical but the logic may diverge in time
            #
            all = redis.hgetall('disruption:roadclosure')
            found = false

            case alert["source"]
                when "Waze"
                    all.each { |key,value|
                        hc = JSON.parse(value)
                        if hc["unique disruption number"] == alert["unique disruption number"] then
                            found = true
                            redis.hset("disruption:roadclosure", key, alert.to_json)
                            logger.debug('Referee') { "UPDATED roadclosure\nhc=#{hc}\nalert=#{alert}" }
                            break
                        end
                    }
                    if found == false then                                   # create a new traffic_jam entry
                        id = redis.incr("roadclosure-id")
                        redis.hset("disruption:roadclosure", id, alert.to_json)
                        logger.debug('Referee') { "CREATED a new roadclosure key=#{id} alert=#{alert}" }
                    end
                when "CDLoiret"
                    all.each { |key,value|
                        hc = JSON.parse(value)
                        if hc["unique disruption number"] == alert["unique disruption number"] then
                            found = true
                            redis.hset("disruption:roadclosure", key, alert.to_json)
                            logger.debug('Referee') { "UPDATED roadclosure\nhc=#{hc}\nalert=#{alert}" }
                            break
                        end
                    }
                    if found == false then                                   # create a new traffic_jam entry
                        id = redis.incr("roadclosure-id")
                        redis.hset("disruption:roadclosure", id, alert.to_json)
                        logger.debug('Referee') { "CREATED a new roadclosure key=#{id} alert=#{alert}" }
                    end
                else
                    logger.error('Referee') { "roadclosure alert with source #{alert["source"]} not implemented\nalert=#{alert}" }
            end
        else
            logger.error('Referee') { "Alert type #{r[1]} not yet implemented" }
    end
end

#{"uuid"=>"d50a8cc6-5044-35c0-9583-6c8753af1ac9", 
#"direction"=>106,
#"visibility"=>"yes",
#"source"=>"Waze",
#"geolocation"=>{"x"=>2.399949, "y"=>47.774346},
#"short_description"=>" ",
#"detailed_description"=>"Accident important",
#"planned_start_date"=>"2019-04-30 12-28",
#"actual_start_date"=>"2019-04-30 12-28",
#"type"=>"accident",
#"severity"=>4,
#"planned_end_date"=>"2019-04-30 14-28",
#"actual_end_date"=>"2019-04-30 14-28",
#"planned_duration"=>7200
#}

#    disruption = Hash.new()
#    disruption["uuid"]
#    disruption["direction"]
#    disruption["visibility"]
#    disruption["source"]
#    disruption["geolocation"]
#    disruption["short_description"]
#    disruption["detailled_description"]
#    disruption["planned_start_date"]
#    disruption["severity"]
#    disruption["planned_end_date"]
#    disruption["planned_duration"]

#
# List of disruption type
#
#   'roadworks'=>'history:roadworks',
#   'roadclosure'=>'history:roadclosure',
#   'traffic_jam'=>'history:traffic_jam',
#   'flood'=>'history:flood',
#   'accident'=>'history:accident',
#   'animal'=>'history:animal',
#   'hazard'=>'history:hazard',
#   'serious_hazard'=>'history:serious_hazard',
#   'landslide'=>'history:landslide',
#   'technological_risk'=>'history:technological_risk',
#   'attack'=>'history:attack',
#   'market'=>'history:market',
#   'local_event'=>'history:local_event'

