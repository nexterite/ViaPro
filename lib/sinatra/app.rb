require 'sinatra'
require 'logger'
require "redis"
require 'json'
require "securerandom"

require_relative "geo"
require_relative "event"
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
    public_dir= "#{root}/data/sinatra"
    weblogdir = "#{logdir}/puma"

    generalfile  = "#{initdir}/general.ini"
    severity     = "#{initdir}/severity.ini"
    logfile      = "#{logdir}/app.log"
    weblogfile   = "#{weblogdir}/access.log"
    filegeo      = "#{datadir}/cities.yml"
    distance     = 10
#
#   Initialization
#
    configure do
        f1 = File.new(weblogfile, 'a+')
        f1.sync = true
        use Rack::CommonLogger, f1
        set :public_dir, public_dir
    end
    
    general = Hash.new()
    if File.exist?(generalfile) == true then
        File.open(generalfile, 'r') { |f|
            f.each_line { |line|
                l = line.chomp.split('=')
                general[l[0]] = l[1]
            }
        }
    end

    f2 = File.new(logfile, 'a+')
    f2.sync = true
    logger = Logger.new(f2)
    if general.has_key?('Log_level') == true then
        logger.level = general['Log_level']
    else
        logger.level = 'ERROR'
    end

    logger.info('Sinatra') { "sinatra agent called at #{Time.now}" }
    redis = Redis.new(host:"localhost", port:6379, db:0)
    logger.info('Sinatra') { "Redis connected" }

    geo_id = GeoFinder.new(filegeo, distance)
    if geo_id.error == true then
        logger.error('Sinatra') { "GeoFinder initialization failed, search thru coordinates is disabled}" }
        finder = false
    else
        logger.info('Sinatra') { "GeoFinder initialized, search thru coordinates is activated}" }
        finder = true
    end

    event_id = EventChk.new(severity)
    if event_id.error == true then
        logger.error('Sinatra') { "EventChk initialization failed, POST is disabled" }
        post_enabled = false
    else
        logger.info('Sinatra') { "EventChk initialized, POST is activated" }
        post_enabled = true
    end
    
    version = 'v1.0'
    prefix = "ilayer/#{version}"
    #
    # match GET /$prefix/type
    #   or
    #       GET /$prefix/type?keyname=mykey
    #       GET /$prefix/type?lat=mylat@long=mylong ( for cweather )
    #
    #   where type is the key in the hash
    #   the values holds :
    #     Redis keyname
    #     if the url supports query parameters and if so, what it's the key name
    #
    disruptions = {
    'cweather'           => {"rediskey" =>"current-weather" ,              "keyid"=>nil                  ,"mode"=>'all' ,"keyname"=>'city'},
    'fweather'           => {"rediskey" =>"forecast-weather",              "keyid"=>nil                  ,"mode"=>'none',"keyname"=>'city'},
    'aweather'           => {"rediskey" =>"alerts-weather",                "keyid"=>nil                  ,"mode"=>'all', "keyname"=> nil  },
    'aquality'           => {"rediskey" =>"air-quality",                   "keyid"=>nil                  ,"mode"=>'all', "keyname"=>'city'},
    'gstation'           => {"rediskey" =>"gstation",                      "keyid"=>nil                  ,"mode"=>'all', "keyname"=>'id'  },
    'careas'             => {"rediskey" =>"carpool",                       "keyid"=>nil                  ,"mode"=>'all', "keyname"=> nil  },
    'bparking'           => {"rediskey" =>"bparking",                      "keyid"=>nil                  ,"mode"=>'all', "keyname"=> nil  },
    'parking'            => {"rediskey" =>"parking",                       "keyid"=>nil                  ,"mode"=>'all', "keyname"=> nil  },
    'jams'               => {"rediskey" =>"jams",                          "keyid"=>nil                  ,"mode"=>'all', "keyname"=> nil  },
    'risk_areas'         => {"rediskey" =>"risk_areas",                    "keyid"=>nil                  ,"mode"=>'all', "keyname"=> 'key' },
    'flood_history'      => {"rediskey" =>"flood_history",                 "keyid"=>nil                  ,"mode"=>'all', "keyname"=> nil  },
    'roadworks'          => {"rediskey" =>"disruption:roadworks",          "keyid"=>"roadworks-id"       ,"mode"=>'all', "keyname"=>'key' },
    'roadclosure'        => {"rediskey" =>"disruption:roadclosure",        "keyid"=>"roadclosure-id"     ,"mode"=>'all', "keyname"=>'key' },
    'traffic_jam'        => {"rediskey" =>"disruption:traffic_jam",        "keyid"=>"traffic_jam-id"     ,"mode"=>'all', "keyname"=>'key' },
    'flood'              => {"rediskey" =>"disruption:flood",              "keyid"=>"flood-id"           ,"mode"=>'all', "keyname"=>'key' },
    'accident'           => {"rediskey" =>"disruption:accident",           "keyid"=>"accident-id"        ,"mode"=>'all', "keyname"=>'key' },
    'animal'             => {"rediskey" =>"disruption:animal",             "keyid"=>"animal-id"          ,"mode"=>'all', "keyname"=>'key' },
    'hazard'             => {"rediskey" =>"disruption:hazard",             "keyid"=>"hazard-id"          ,"mode"=>'all', "keyname"=>'key' },
    'serious_hazard'     => {"rediskey" =>"disruption:serious_hazard",     "keyid"=>"serious_hazard-id"  ,"mode"=>'all', "keyname"=>'key' },
    'landslide'          => {"rediskey" =>"disruption:landslide",          "keyid"=>"landslide-id"       ,"mode"=>'all', "keyname"=>'key' },
    'technological_risk' => {"rediskey" =>"disruption:technological_risk", "keyid"=>"technological_risk-id","mode"=>'all', "keyname"=>'key' },
    'attack'             => {"rediskey" =>"disruption:attack",             "keyid"=>"attack-id"          ,"mode"=>'all', "keyname"=>'key' },
    'market'             => {"rediskey" =>"disruption:market",             "keyid"=>"market-id"          ,"mode"=>'all', "keyname"=>'key' },
    'local_event'        => {"rediskey" =>"disruption:local_event",        "keyid"=>"local_event-id"     ,"mode"=>'all', "keyname"=>'key' }
    }
    
    hist_objects = {
    'roadworks'=>'history:roadworks',
    'roadclosure'=>'history:roadclosure',
    'traffic_jam'=>'history:traffic_jam', 
    'flood'=>'history:flood', 
    'accident'=>'history:accident', 
    'animal'=>'history:animal', 
    'hazard'=>'history:hazard',
    'serious_hazard'=>'history:serious_hazard',
    'landslide'=>'history:landslide', 
    'technological_risk'=>'history:technological_risk',
    'attack'=>'history:attack',
    'market'=>'history:market',
    'local_event'=>'history:local_event'
    }

    logger.debug('Sinatra') { "disruptions=#{disruptions}" }
    #
    # 1. GET for history object
    #
    get "/#{prefix}/history" do
        #
        # match GET /$prefix/history
        #
        logger.debug('Sinatra') { "GET call /history params=#{params}" }
        if (params.has_key?("type") == false) || (params.has_key?("key") == false) then
            logger.error('Sinatra') { "Call /history without type or key is invalid" }
            status 400
            body "Invalid type"
        elsif hist_objects.has_key?(params["type"]) == false then
            logger.error('Sinatra') { "Invalid disruption type in /history call" }
            status 400
            body "Invalid disruption type"
        else
            rediskey = hist_objects[params["type"]]           # corresponding Redis key name
            key = params["key"]

            case params.length                                # check if params provided
                when 2, 3
                    #
                    # get public and/or private history
                    #
                    ret = redis.hget(rediskey, key) # get the whole Redis hash
                    if ret == nil then
                        status 200
                        body "{}"
                    elsif params.length == 2 then
                        x = { key => ret }.to_json            # return the whole key
                        status 200
                        body  x
                    elsif params.has_key?("private") == true then
                        x = JSON.parse(ret)
                        y =  { key => {"private description" => x["private description"]}}.to_json
                        status 200
                        body y
                    elsif params.has_key?("public") == true then
                        x = JSON.parse(ret)
                        y = { key => {"public description" => x["public description"]}}.to_json
                        status 200
                        body y
                    else
                        logger.error('Sinatra') { "Call /history with the params #{params} is not accepted" }
                        status 405
                        body "Method not allowed"
                    end
                else
                    #
                    # 1 parameter or > 3 parameters
                    #
                    logger.error('Sinatra') { "Call /history with params #{params} is not supported" }
                    status 405
                    body "Method not allowed"
            end
        end
    end
    #
    # 2. GET for admin object
    #
    get "/#{prefix}/admin" do
        #
        # match GET /$prefix/admin
        #
        logger.debug('Sinatra') { "GET call /admin params=#{params}" }
        if params.has_key?("key") == false then
            logger.error('Sinatra') { "Call /admin without type or key is invalid" }
            status 400
            body "Invalid type"
        else
            key = params["key"]
            if key == "all" then
                objects = disruptions.keys
            else
                objects = key.split(',')
            end
            database = Hash.new()
            logger.debug('Sinatra') { "GET call /admin #{objects.length} objects to dump" }
            objects.each { |object|
                if disruptions.has_key?(object) == false then
                    logger.error('Sinatra') { "Call /admin invalid object type #{object}" }
                    next
                end
                rediskey = disruptions[object]["rediskey"]                # corresponding Redis key name
                ret = redis.hgetall(rediskey)
                if ret == nil then
                    database[object] = {}
                else
                    nhash = Hash.new()
                    ret.each { |key,value|
                        nhash[key] = JSON.parse(value)
                    }
                    database[object] = nhash
                end
            }
            status 200
            #
            # generate the temporary json file
            #
            filename = "#{SecureRandom.uuid}.json"
            fullpath = "#{public_dir}/#{filename}"
            File.open(fullpath, "w") { |f|
                f.puts database.to_json
            }
            send_file fullpath, :filename => filename, :type => 'application/json'
        end
    end
    #
    # 3. GET for current objects 
    #
    get "/#{prefix}/:type" do |type|
        #
        # match GET /$prefix/type
        #
        logger.debug('Sinatra') { "GET call /#{type} params=#{params}" }
        if disruptions.has_key?(type) == false then
            logger.error('Sinatra') { "Call /#{type} is invalid" }
            status 400
            body "Invalid object type"
        else
            rediskey = disruptions[type]["rediskey"]      # corresponding Redis key name
            mode = disruptions[type]["mode"]              # if :all we accept url with and without params
                                                          #    :none we do not accept url without params
            keyname = disruptions[type]["keyname"]        #  keyname within url

            case params.length                            # check if params provided
                when 1
                    #
                    # no params  provided
                    #
                    case mode
                        when 'all'                        # We accept url without query params
                            ret = redis.hgetall(rediskey) # get the whole Redis hash
                            if ret == nil then
                                body "{}"
                            else
                               nhash = Hash.new()
                                ret.each { |key,value|
                                    nhash[key] = JSON.parse(value)
                                }
                                body nhash.to_json
                            end
                            status 200
                        when 'none'                       # We do not accept url without params
                            logger.error('Sinatra') { "Call /#{type} should be done with params" }
                            body "For #{type} you should provide query params"
                            status 405
                    end
                when 2
                    #
                    # params provided : 1 parameter
                    #
                    if keyname == nil then
                        logger.error('Sinatra') { "Call /#{type} with params is not valid" }
                        status 405
                        body "Method not allowed"
                    elsif params.has_key?(keyname) == true then
                        id = params[keyname]
                        if type == "risk_areas" then
                            ret = redis.hgetall(rediskey) # get the whole Redis hash
                            if ret == nil then
                                body "{}"
                            else
                                nhash = Hash.new()
                                ret.each { |key,value|
                                    v = JSON.parse(value)
                                    nhash[key] = v if v["type"] == id
                                }
                                if nhash.empty? == true  then
                                    body "{}"
                                else
                                    body nhash.to_json
                                end
                            end
                        else
                            ret = redis.hget(rediskey, id)    # get the partial hash given by the key id
                            if ret == nil then
                                body "{}"
                            else
                                h = JSON.parse(ret)           # Seems unecessary but the JSON parse and conversion doesn't work exactly on all 
                                body h.to_json                # Ruby version so better to provide an uniform level to all clients
                            end
                        end
                        status 200
                    else
                        logger.error('Sinatra') { "Call /#{type} with the params #{params} is not accepted" }
                        status 405
                        body "Method not allowed"
                    end
                when 3
                    #
                    # params provided : 2 parameters
                    #
                    if keyname == nil then
                        logger.error('Sinatra') { "Call /#{type} with params is not valid" }
                        status 405
                        body "Method not allowed"
                    elsif ((type == "cweather") || (type == "fweather")) && params.has_key?("lat") && params.has_key?("long") then
                        if finder == true then
                            id = geo_id.geo_locate(params["lat"], params["long"])
                            if geo_id.error == false then
                                ret = redis.hget(rediskey, id)    # get the partial hash given by the key id
                                if ret == nil then
                                    body "{}"
                                else
                                    h = JSON.parse(ret)       # Seems unecessary but the JSON parse and conversion doesn't work exactly on all 
                                    body h.to_json            # Ruby version so better to provide an uniform level to all clients
                                end
                                status 200
                            else
                                logger.error('Sinatra') { "coordinates provided thru #{params} faraway from the radius of #{distance}km" }
                                status 404
                                body "nearest city is more than #{distance}km from current point"
                            end
                        else
                            logger.error('Sinatra') { "GeoFinder function disabled}" }
                        end
                    else
                        logger.error('Sinatra') { "Call /#{type} with the params #{params} is not accepted" }
                        status 405
                        body "Method not allowed"
                    end
                else
                    #
                    # More than 2 parameters
                    #
                    logger.error('Sinatra') { "Call /#{type} with params #{params} is not supported" }
                    status 405
                    body "Method not allowed"
            end
        end
    end
    #
    # 4. GET for disruption objects
    #
    get "/#{prefix}/disruption/:type" do |type|
        #
        # match GET /$prefix/disruption/type
        #
        logger.debug('Sinatra') { "GET call /disruption/#{type} params=#{params}" }
        if disruptions.has_key?(type) == false then
            logger.error('Sinatra') { "Call /disruption/#{type} is invalid" }
            status 400
            body "Invalid disruption type"
        else
            rediskey = disruptions[type]["rediskey"]      # corresponding Redis key name
            mode = disruptions[type]["mode"]              # if :all we accept url with and without params
                                                          #    :none we do not accept url without params
            keyname = disruptions[type]["keyname"]        #  keyname within url

            case params.length                            # check if params provided
                when 1
                    #
                    # no params  provided
                    #
                    case mode
                        when 'all'                        # We accept url without query params
                            ret = redis.hgetall(rediskey) # get the whole Redis hash
                            if ret == nil then
                                body "{}"
                            else
                               nhash = Hash.new()
                                ret.each { |key,value|
                                    nhash[key] = JSON.parse(value)
                                }
                                body nhash.to_json
                            end
                            status 200
                        when 'none'                       # We do not accept url without params
                            logger.error('Sinatra') { "Call /#{type} should be done with params" }
                            body "For #{type} you should provide query params"
                            status 405
                    end
                when 2
                    #
                    # params provided : 1 parameter
                    #
                    if keyname == nil then
                        logger.error('Sinatra') { "Call /#{type} with params is not valid" }
                        status 405
                        body "Method not allowed"
                    elsif params.has_key?(keyname) == true then
                        id = params[keyname]
                        ret = redis.hget(rediskey, id)    # get the partial hash given by the key id
                        if ret == nil then
                            body "{}"
                        else
                            h = JSON.parse(ret)           # Seems unecessary but the JSON parse and conversion doesn't work exactly on all 
                            body h.to_json                # Ruby version so better to provide an uniform level to all clients
                        end
                        status 200
                    else
                        logger.error('Sinatra') { "Call /#{type} with the params #{params} is not accepted" }
                        status 405
                        body "Method not allowed"
                    end
                else
                    #
                    # More than 1 parameters
                    #
                    logger.error('Sinatra') { "Call /#{type} with params #{params} is not supported" }
                    status 405
                    body "Method not allowed"
            end
        end
    end
    #
    # 5. POST for disruption objects
    #
    post "/#{prefix}/disruption/:type" do |type|
        #
        # match POST /$prefix/disruption/type
        #
        logger.debug('Sinatra') { "POST call /disruption/#{type} params=#{params}" }
   
        if disruptions.has_key?(type) == false then
            logger.error('Sinatra') { "Call /disruption/#{type} is invalid" }
            status 400
            body "Invalid disruption type"
        else
           if post_enabled == false then
               logger.error('Sinatra') { "POST call was disabled" }
               status 400
               body "Initialization error, POST was disabled"
           else
               event = event_id.check_event(request.body.read)

               if event_id.error == false then

                   keyid = disruptions[type]["keyid"]
                   rediskey = disruptions[type]["rediskey"]      # corresponding Redis key name

                   id = redis.incr(keyid)
                   redis.hset(rediskey, id, event)

                   logger.debug('Sinatra') { "CREATED a new accident alert key=#{id} alert=#{event}" }
                   status 200
                   body "#{id}"
               else
                   status 404
                   body event_id.error_message
               end
           end
        end
    end
    #
    # 6. PUT for disruption objects
    #
    put "/#{prefix}/disruption/:type" do |type|
        #
        # match PUT /$prefix/disruption/type
        #
        logger.debug('Sinatra') { "PUT call /disruption/#{type} params=#{params}" }
        if disruptions.has_key?(type) == false then
            logger.error('Sinatra') { "Call /disruption/#{type} is invalid" }
            status 400
            body "Invalid disruption type"
        else
            keyname = disruptions[type]["keyname"]        #  keyname within url
            if params.has_key?(keyname) == false then
                logger.error('Sinatra') { "Call /#{type} without params is not valid" }
                status 405
                body "Method not allowed, must provide params"
            else
                event = event_id.check_event(request.body.read)

                if event_id.error == false then
                    rediskey = disruptions[type]["rediskey"]      # corresponding Redis key name
                    id = params[keyname]                          # the key we want to modify
                    hist_hash = hist_objects[type]

                    redis.watch(rediskey, hist_hash) do
                        history = redis.hget(hist_hash, id)       # get history of modifications for this disruption object
                        ret = redis.hget(rediskey, id)
                        h = event_id.check_history(history, ret, event)
                        if ret != nil
                            #
                            # check difference between previous and actual public and private fields
                            # 
                            redis.multi do |multi|
                                multi.hset(rediskey, id, event)
                                if h != nil then
                                    multi.hset(hist_hash, id, h)
                                end
                            end
                            status 200
                            body "ok"
                            logger.debug('Sinatra') { "UPDATED event key=#{id} alert=#{event}" }
                        else
                            redis.unwatch
                            status 404
                            body "missing key"
                        end
                    end
                else
                    status 404
                    body event_id.error_message
                end
            end
        end
    end
    #
    # 7. DEL for disruption objects
    #
    delete "/#{prefix}/disruption/:type" do |type|
        #
        # match DEL /$prefix/disruption/type
        #
        logger.debug('Sinatra') { "DEL call /disruption/#{type} params=#{params}" }
        if disruptions.has_key?(type) == false then
            logger.error('Sinatra') { "Call /disruption/#{type} is invalid" }
            status 400
            body "Invalid disruption type"
        else
            keyname = disruptions[type]["keyname"]        #  keyname within url
            if params.has_key?(keyname) == false then
                logger.error('Sinatra') { "Call /#{type} without params is not valid" }
                status 405
                body "Method not allowed, must provide params"
            else
                rediskey = disruptions[type]["rediskey"]      # corresponding Redis key name
                id = params[keyname]
                hist_hash = hist_objects[type]

                ret = redis.watch(rediskey, hist_hash) do
                    redis.multi do |multi|
                        multi.hdel(rediskey, id)
                        multi.hdel(hist_hash, id)
                    end
                end
                status 200
                if ret[0] == 0 then
                    body "missing key"
                else
                    body "ok"
                end
                logger.debug('Sinatra') { "DELETED event #{keyname}=#{id}" }
            end
        end
    end

    get "/" do
        status 400
        logger.error('Sinatra') { "Invalid route /" }
        body 'Missing route'
    end
    
    get "/*" do
        status 400
        logger.error('Sinatra') { "Invalid route /" }
        body "Incorrect route"
    end
