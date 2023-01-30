require 'rufus-scheduler'
    
    def trace(ret, logger, process)
    
        if ret == false then
            logger.error('Rufus') { "Failed scheduling #{process}" }
        elsif ret == nil then
            logger.error('Rufus') { "Scheduling for #{process} cannot be done" }
        else
            logger.info('Rufus') { "Scheduling for #{process} was done" }
        end
    
    end
#
# Main BEGOOD scheduling manager
#
    root = ENV["BEGOOD_PATH"]
    if root == nil then
         puts "Critical error with rufus, missing BEGOOD_PATH"
         exit 1
    end
#
#   Set common variables
#
    bindir  = "#{root}/bin"
    logdir  = "#{root}/log"
    initdir = "#{root}/init"

    command      = "#{bindir}/collector"                        # unique shell command for starting data collectors
    generalfile  = "#{initdir}/general.ini"
    logfile      = "#{logdir}/app.log"
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

    logger.info('Scheduler') { "scheduler agent called at #{Time.now}" }
    
    eos = false                                            # end of scheduling flag
    Signal.trap("TERM") do
        eos = true
    end
    
    scheduler = Rufus::Scheduler.new()
    
    #
    # Internal watch-dog for shutdown requirements
    #
    scheduler.every '2s' do
        if eos == true then
            logger.info('Rufus') { "Rufus got TERM signal and will shutdown" }
            logger.close
            scheduler.shutdown(:kill)
            exit
        end
    end
    #
    # 1. Current weather object - called every 2 hours, force a 1st call at startup
    #
    scheduler.every '2h', :first_in => '1s' do
        process = "cweather.py"
        value = system(command, process)
        trace(value, logger, process)
    end
    #
    # 2. Forecasted weather object - called every 2 hours, starts 15 minutes hour after cweather
    #
    scheduler.every '2h', :first_in => '15m' do
        process = "fweather.py"
        value = system(command, process)
        trace(value, logger, process)
    end
    #
    # 3.0 Weather alerts object - force a 1st call at startup
    #
    scheduler.in '1s' do
        process = "aweather.py"
        value = system(command, process)
        trace(value, logger, process)
    end
     #
     # 3.1 Weather alerts object - every day at 06:01
     #
    scheduler.cron '01 06 * * *' do
        process = "aweather.py"
        value = system(command, process)
        trace(value, logger, process)
    end
    #
    # 3.2 Weather alerts object - every day at 14:01
    #
    scheduler.cron '01 14 * * *' do
        process = "aweather.py"
        value = system(command, process)
        trace(value, logger, process)
    end
    #
    # 4.0 Air quality object - force a 1st call at startup
    #
    scheduler.in '1s' do
        process = "aquality.py"
        value = system(command, process)
        trace(value, logger, process)
    end
    #
    # 4.1 Air quality object - every day at 18:05
    #
    scheduler.cron '05 18 * * *' do
        process = "aquality.py"
        value = system(command, process)
        trace(value, logger, process)
    end
    #
    # 5.1 Disruption object - roadworks - every 3 days - Loiret official file
    #
    #  scheduler.every '3d', :first_in => '2s' do
    #      process = "roadworks.py"
    #      value = system(command, process)
    #      trace(value, logger, process)
    #  end
    #
    # 5.2 Disruption object - roadclosure - every day - Loiret official file
    #
    #   scheduler.every '1d', :first_in => '3s' do
    #       process = "roadclosure.py"
    #       value = system(command, process)
    #       trace(value, logger, process)
    #   end
    #
    # 5.3 Waze agent - every 5 minutes
    #  Deals with
    #
    #   - accident
    #   - hazard
    #   - serious_hazard
    #   - animal
    #   - roadwork
    #   - traffic_jam
    #   - roadclosure
    #
    #  scheduler.every '5m', :first_in => '4s' do
    #      process = "waze.rb"
    #      value = system(command, process)
    #      trace(value, logger, process)
    #  end
    #
    # 5.4 Disruption object - traffic jam - not called from here, external agent 
    #
    # traffic_jam code lays elsewhere
    #
    
    #
    # 5.5 Disruption object - flood - not called from here, external agent
    #
    # flood code lays elsewhere
    #
    
    #
    # 5.6 Disruption object - accident - not called from here, external agent
    #
    # accident code lays elsewhere
    #
    
    #
    # 5.7 Disruption object - hazard - not called from here, external agent
    #
    # hazard code lays elsewhere
    #
    
    #
    # 5.8 Disruption object - animal - not called from here, external agent
    #
    # animal code lays elsewhere
    #
    
    #
    # 5.9 Disruption object - landslide -  not called from here, external agent
    #
    # landslide code lays elsewhere
    #
    
    #
    # 5.10 Disruption object - technological_risk -  not called from here, external agent
    #
    # technological_risk code lays elsewhere
    #
    
    #
    # 5.11 Disruption object - attack - not called from here, external agent
    #
    # attack code lays elsewhere
    #
    
    #
    # 5.12 Disruption object - serious_hazard - not called from here, external agent
    #
    # serious_hazard code lays elsewhere
    #
    
    #
    # 5.13 Disruption object - market - 
    #
    # market
    #
    scheduler.every '6h', :first_in => '5s' do
        process = "market.py"
        value = system(command, process)
        trace(value, logger, process)
    end
    #
    # 5.13 Disruption object - local_event - every 3 days
    #
    # local_event
    #
    scheduler.every '6h', :first_in => '6s' do
        process = "local_event.py"
        value = system(command, process)
        trace(value, logger, process)
    end
    #
    # 6. Gas stations - gstation - every 6 hours
    #
    scheduler.every '6h', :first_in => '7s' do
        process = "gstation.py"
        value = system(command, process)
        trace(value, logger, process)
    end
    #
    # 7. Car pool areas - careas - every month
    #
    scheduler.every '30d', :first_in => '8s' do
        process = "carpool.py"
        value = system(command, process)
        trace(value, logger, process)
    end
    #
    # 8. Parking places in Orleans
    #
    #  scheduler.every '10m', :first_in => '9s' do
    #      process = "parking.rb"
    #      value = system(command, process)
    #      trace(value, logger, process)
    #  end
    #
    # 9. Bicycles parkings - bparking - every week
    #
    scheduler.every '30d', :first_in => '10s' do
        process = "bparking.py"
        value = system(command, process)
        trace(value, logger, process)
    end
    #
    # 10. Risk areas - every month
    #
    scheduler.every '30d', :first_in => '11s' do
        process = "risk_areas.py"
        value = system(command, process)
        trace(value, logger, process)
    end
    #
    # 11. Flood history - every month
    #
    scheduler.every '30d', :first_in => '12s' do
        process = "flood_history.rb"
        value = system(command, process)
        trace(value, logger, process)
    end
    
    scheduler.join
