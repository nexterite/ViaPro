require 'json'
require 'date'
require 'logger'
require 'redis'
require 'time'
#
# BEGOOD - Delete agent
#
# Main goal is to:
#
#  - take entries from various alerts lists and delete Redis entry
#  - deal with concurrent accesses to the same alert
#  - deal with alert proximities
#
#  - FOR DELETE tasks
#
    root = ENV["BEGOOD_PATH"]
    if root == nil then
         puts "Critical error with delete.rb, missing BEGOOD_PATH"
         exit 1
    end
#
#   Set cvariables
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

    logger.info('Delete') { "Delete agent called at #{Time.now}" }

    redis = Redis.new(host: "localhost", port: 6379, db: 0)
    logger.info('Delete') { "Redis connected" }

# 
#   Loop over disruption alerts lists and dispatch according to criterias
#
#   There is only 1 list par disruption type, name is object_list like accident_list
#   some lists may be empty
#   There are 13 different types of disruptions
#
while true

    begin
    r = redis.brpop('serious_hazard_delete','accident_delete','traffic_jam_delete','hazard_delete','roadwork_delete','roadclosure_delete','animal_delete', 'flood_delete', 'landslide_delete', 'technological_risk_delete', 'attack_delete', 'market_delete', 'local_event_delete',60)
    rescue Interrupt
        logger.info('Delete') { "We got an interrupt and will immediately leave" }
        logger.close
        exit
    end 
    next if r == nil
    #
    # We got an alert
    #
    alert = JSON.parse(r[1])
    #
    # Main processing area
    #
    case r[0]
        when 'accident_delete'
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
                        redis.hdel('disruption:accident', key)        # remove the found alert
                        logger.debug('Delete') { "DELETED accident\nkey=#{key}\nalert=#{alert}" }
                        break
                    end
                }
                if found == false then                                   # create a new accident entry
                    logger.error('Delete') { "DELETE an inexistant event accident alert alert=#{alert}" }
                end
            else
                logger.error('Delete') { "Delete accident alert with type #{alert["source"]} not implemented yet\nalert=#{alert}" }
            end

        when 'hazard_delete'
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
                        redis.hdel('disruption:hazard', key)          # remove the found alert because the new duration is 1 second
                        logger.debug('Delete') { "DELETED hazard\nkey=#{key}\nalert=#{alert}" }
                        break
                    end
                }
                if found == false then                                   # create a new hazard entry
                    logger.error('Delete') { "DELETE an inexistant hazard alert=#{alert}" }
                end
            else
                logger.error('Delete') { "hazard alert with source #{alert["source"]} not implemented yet\nalert=#{alert}" }
            end
        when 'serious_hazard_delete'
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
                        redis.hdel('disruption:serious_hazard', key)  # remove the found alert because the new duration is 1 second
                        logger.debug('Delete') { "DELETED serious_hazard\nkey=#{key}\nalert=#{alert}" }
                        break
                    end
                }
                if found == false then                                   # create a new serious_hazard entry
                    logger.debug('Delete') { "DELETE an inexistant serious_hazard alert=#{alert}" }
                end
            else
                logger.error('Delete') { "serious_hazard alert with source #{alert["source"]} not implemented yet\nalert=#{alert}" }
            end
        when 'animal_delete'
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
                        redis.hdel('disruption:animal', key)        # remove the found alert because the new duration is 1 second
                        logger.debug('Delete') { "DELETED animal\nkey=#{key}\nalert=#{alert}" }
                        break
                    end
                }
                if found == false then                                   # create a new animal entry
                    logger.debug('Delete') { "DELETE an inexistant animal alert=#{alert}" }
                end
            else
                logger.error('Delete') { "animal alert with source #{alert["source"]} not implemented\nalert=#{alert}" }
            end
        when 'traffic_jam_delete'
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
                        redis.hdel('disruption:traffic_jam', key)        # remove the found alert because the new duration is 1 second
                        logger.debug('Delete') { "DELETED traffic_jam\nkey=#{key}\nalert=#{alert}" }
                        break
                    end
                }
                if found == false then                                   # create a new traffic_jam entry
                    logger.debug('Delete') { "DELETE an inexistant traffic_jam alert=#{alert}" }
                end
            else
                logger.error('Delete') { "traffic_jam alert with source #{alert["source"]} not implemented\nalert=#{alert}" }
            end
        when 'roadwork_delete'
            #
            # ROADWORKS
            #
            # we must loop thru current list of disruption:roadworks and check if this event exist or not
            # "Waze" and "CDLoiret" code may look identical but the logic may diverge over time
            #
            all = redis.hgetall('disruption:roadworks')
            found = false

            case alert["source"]
                when "Waze"
                    all.each { |key,value|
                        hc = JSON.parse(value)
                        if hc["unique disruption number"] == alert["unique disruption number"] then
                            found = true
                            redis.hdel('disruption:roadworks', key)        # remove the found alert because the new duration is 1 second
                            logger.debug('Delete') { "DELETED roadworks\nkey=#{key}\nalert=#{alert}" }
                            break
                        end
                    }
                    if found == false then                                   # create a new traffic_jam entry
                        logger.debug('Delete') { "DELETE an inexistant roadworks alert=#{alert}" }
                    end
                when "CDLoiret"
                    all.each { |key,value|
                        hc = JSON.parse(value)
                        if hc["unique disruption number"] == alert["unique disruption number"] then
                            found = true
                            redis.hdel('disruption:roadworks', key)        # remove the found alert because the new duration is 1 second
                            logger.debug('Delete') { "DELETED roadworks\nkey=#{key}\nalert=#{alert}" }
                            break
                        end
                    }
                    if found == false then                                   # create a new traffic_jam entry
                        logger.debug('Delete') { "DELETE an inexistant roadworks alert=#{alert}" }
                    end
                else
                    logger.error('Delete') { "roadworks alert with source #{alert["source"]} not implemented\nalert=#{alert}" }
            end
        when 'roadclosure_delete'
            #
            # ROADCLOSURE
            #
            # we must loop thru current list of disruption:roadclosure and check if this event exist or not
            # "Waze" and "CDLoiret" code may look identical but the logic may diverge over time
            #
            all = redis.hgetall('disruption:roadclosure')
            found = false

            case alert["source"]
                when "Waze"
                    all.each { |key,value|
                        hc = JSON.parse(value)
                        if hc["unique disruption number"] == alert["unique disruption number"] then
                            found = true
                            redis.hdel('disruption:roadclosure', key)        # remove the found alert because the new duration is 1 second
                            logger.debug('Delete') { "DELETED roadclosure\nkey=#{key}\nalert=#{alert}" }
                            break
                        end
                    }
                    if found == false then                                   # create a new traffic_jam entry
                        logger.debug('Delete') { "DELETE a new roadclosure alert=#{alert}" }
                    end
                when "CDLoiret"
                    all.each { |key,value|
                        hc = JSON.parse(value)
                        if hc["unique disruption number"] == alert["unique disruption number"] then
                            found = true
                            redis.hdel('disruption:roadclosure', key)        # remove the found alert because the new duration is 1 second
                            logger.debug('Delete') { "DELETED roadclosure\nalert=#{alert}" }
                            break
                        end
                    }
                    if found == false then                                   # create a new traffic_jam entry
                        logger.debug('Delete') { "DELETED an inexistant roadclosure alert=#{alert}" }
                    end
                else
                    logger.error('Delete') { "roadclosure alert with source #{alert["source"]} not implemented\nalert=#{alert}" }
            end
        else
            logger.error('Delete') { "Unknown alert type #{r[1]}" }
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

