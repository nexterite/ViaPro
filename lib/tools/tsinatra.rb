require 'net/http'
require 'openssl'
require 'json'

class Errors

    attr_reader :code
    attr_reader :message
    attr_reader :body

    def initialize(code, message, body)

        @code = code
        @message = message
        @body = body
    end
end
#
#
#
def httpget(query,remote, params=nil)

    if remote == true then
#       puts "query=#{query}"
        uri = URI(query)

        if params != nil then
            uri.query = URI.encode_www_form(params)
#           puts uri.inspect
        end

        request = Net::HTTP::Get.new(uri)
        request.basic_auth 'samu45', 'samu45'

        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = true                            # specify https connection
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
#       http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    else
#       puts "query=#{query}"
        uri = URI(query)

        if params != nil then
            uri.query = URI.encode_www_form(params)
#           puts uri.inspect
        end

        request = Net::HTTP::Get.new(uri)
        http = Net::HTTP.new(uri.hostname, uri.port)
    end
    http.request(request) do |response|
        return Errors.new(response.code, response.message, response.read_body)
    end
end
#
#
#
def httppost(query, remote, event)

    if remote == true then
#       puts "query=#{query}"
        uri = URI(query)
#       puts uri.inspect

        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = true                            # specify https connection
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
#       http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Post.new(uri)
        request.basic_auth 'samu45', 'samu45'
    else
#       puts "query=#{query}"
        uri = URI(query)
#       puts uri.inspect

        http = Net::HTTP.new(uri.hostname, uri.port)

        request = Net::HTTP::Post.new(uri)
    end
    request.body = event.to_json
    http.request(request) do |response|
        return Errors.new(response.code, response.message, response.read_body)
    end
end
#
#
#
def httpput(query, remote, event, params)

    if remote == true then
#       puts "query=#{query}"
        uri = URI(query)
        uri.query = URI.encode_www_form(params)
#       puts uri.inspect

        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = true                            # specify https connection
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
#       http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Put.new(uri)
        request.basic_auth 'samu45', 'samu45'
    else
#       puts "query=#{query}"
        uri = URI(query)
        uri.query = URI.encode_www_form(params)
#       puts uri.inspect

        http = Net::HTTP.new(uri.hostname, uri.port)

        request = Net::HTTP::Put.new(uri)
    end
    request.body = event.to_json
    http.request(request) do |response|
        return Errors.new(response.code, response.message, response.read_body)
    end
end
#
#
#
def httpdelete(query,remote, params=nil)

    if remote == true then
#       puts "query=#{query}"
        uri = URI(query)

        if params != nil then
            uri.query = URI.encode_www_form(params)
#           puts uri.inspect
        end

        request = Net::HTTP::Delete.new(uri)
        request.basic_auth 'samu45', 'samu45'

        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = true                            # specify https connection
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
#       http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    else
#       puts "query=#{query}"
        uri = URI(query)

        if params != nil then
            uri.query = URI.encode_www_form(params)
#           puts uri.inspect
        end

        request = Net::HTTP::Get.new(uri)
        http = Net::HTTP.new(uri.hostname, uri.port)
    end
    http.request(request) do |response|
        return Errors.new(response.code, response.message, response.read_body)
    end
end
#
# Host address of Orléans OpenAgenda
#
url = 'http://localhost:9292/ilayer/v1.0/'
urls = 'https://trafficbegood.loiret.fr/ilayer/v1.0/'
#urls = 'https://176.74.38.99/ilayer/v1.0/'
#
locators = [
'cweather',
'fweather',
'aweather',
'aquality',
'gstation',
'careas',
'bparking',
'parking',
'jams',
'risk_areas',
'disruption/roadworks',
'disruption/roadclosure',
'disruption/traffic_jam',
'disruption/flood',
'disruption/accident',
'disruption/hazard',
'disruption/animal',
'disruption/landslide',
'disruption/technological_risk',
'disruption/attack',
'disruption/serious_hazard',
'disruption/market',
'disruption/local_event'
]
locators_with_1_key = [
['cweather', { :city => "Montargis" }],
['fweather', { :city => "Montargis" }],
['aweather', { :city => "Montargis" }],
['aquality', { :city => "Montargis" }],
['risk_areas', { :key => "flood" }],
['disruption/hazard', { :city => "Montargis" }],
['disruption/hazard', { :key => "Montargis" }],
['disruption/hazard', { :key => "504" }]
]
locators_with_2_key = [
['cweather', { :lat => 47.9 , :long => 1.91 }],
['cweather', { :lat => 49.9 , :long => 1.91 }],
['fweather', { :lat => 47.9 , :long => 1.91 }],
['cweather', { :lat => 47.8 , :long => 1.90 }]
]
disruptions = [
'disruption/roadworks',
'disruption/roadclosure',
'disruption/traffic_jam',
'disruption/flood',
'disruption/accident',
'disruption/hazard',
'disruption/animal',
'disruption/landslide',
'disruption/technological_risk',
'disruption/attack',
'disruption/serious_hazard',
'disruption/market',
'disruption/local_event'
]

r = ENV["REMOTE"]
if r == nil then
    puts "REMOTE environment variable was not set to yes or no, it will be forced to yes"
    remote = true
elsif r == 'yes'  then
    remote = true
elsif r == 'no' then
    remote = false
else
    puts "Invalid value #{r} for REMOTE envirnment variable, it will be forced to yes"
    remote = true
end
puts "**** GET - Running LOCATORS only ***"  
locators.each { |loc|
    if remote == true then
        query = urls+loc
    else
        query = url+loc
    end
    ret = httpget(query, remote)
    if ret.code.to_i != 200 then
        puts "Error locator #{loc}"
        puts "code=#{ret.code}"
        puts "message=#{ret.message}"
        puts "Body=#{ret.body}"
     else
        puts "Succesfully locator #{loc}"
     end
}
puts "**** GET - Running LOCATORS with 1 condition on Montargis ***"  
locators_with_1_key.each { |k|

    loc = k[0]
    params = k[1]

    if remote == true then
        query = urls+loc
    else
        query = url+loc
    end
    ret = httpget(query, remote, params)
    if ret.code.to_i != 200 then
        puts "Error locator #{loc}"
        puts "code=#{ret.code}"
        puts "message=#{ret.message}"
        puts "Body=#{ret.body}"
        next
     end
     puts "Succesfully locator #{loc}"
     x = JSON.parse(ret.body)
     if x.empty? == true then
        puts "Empty answer, verify conditions"
     end
}

puts "**** GET - cweather - Running LOCATORS with 2 conditions on lat/long ***"  
    locators_with_2_key.each { |k|

    loc = k[0]
    params = k[1]

    if remote == true then
        query = urls+loc
    else
        query = url+loc
    end
    ret = httpget(query, remote, params)
    if ret.code.to_i != 200 then
        puts "Error locator #{loc}"
        puts "code=#{ret.code}"
        puts "message=#{ret.message}"
        puts "Body=#{ret.body}"
    else
        puts "Succesfully locator #{loc}"
    end
}
exit
puts "**** POST / PUT / DELETE - Running All LOCATORS ***"
event = {
"unique disruption number" => 12001,
"type" => "accident",
"geolocation" => {"lat"=>1.58, "long"=>48.02 },
"direction" => 0,
"severity level" => 4,
"visibility" => 'yes',
"address" => 'D2020',
"planned start date" => "2019-05-07 18:00",
"actual start date" => "Actual time will be set at run time",
"planned end date" => "2019-05-20 18:00",
"actual end date" => "2019-05-20 18:00",
"planned duration" => 3600*24*5,
"source" => "ViaPro",
"short description" => ' ',
"detailed description" => "Test event for POST operation",
"private description" => nil,
"public description" => nil,
"picture" => nil
}

disruptions.each { |loc|
    if remote == true then
        query = urls+loc
        q = urls+'history'
    else
        query = url+loc
        q = url+'history'
    end
    if loc =~ /[a-z].*\/([a-z].*)$/ then
        event["type"] = $1
    else
        event["type"] = nil
    end
    event["actual start date"] = Time.now().to_s
    event["private description"] = nil
    event["public description"] = nil
    ret = httppost(query, remote, event)
    if ret.code.to_i != 200 then
        puts "POST error with #{loc} locator"
        puts "code=#{ret.code}"
        puts "message=#{ret.message}"
        puts "Body=#{ret.body}"
        next
    else
        puts "Succesfully POST #{loc} locator"
    end
    key = ret.body
    puts "key=#{key}"
    #
    # Verify successful POST
    #
    # verify by a new GET
    #
    ret = httpget(query, remote, { :key => key } )
    if ret.code.to_i != 200 then
        puts "GET error with #{loc} locator"
        puts "code=#{ret.code}"
        puts "message=#{ret.message}"
        puts "Body=#{ret.body}"
        next
    else
        puts "Succesfully GET #{loc} locator"
    end
#   puts "Body=#{ret.body}"
    #
    # Compare what we get with what we sent
    #
    puts "Compare what we POST with what we GET"
    x = JSON.parse(ret.body)
    if x != event then
        puts "We get a bad event from viaFacil\nevent=#{event}\nbody=#{x}"
        exit
    else
        puts "We got the same object"
    end
    #
    # We modify the object
    #
    event["actual start date"] = Time.now().to_s
    ret = httpput(query, remote, event, { :key => key} )
    if ret.code.to_i != 200 then
        puts "PUT error with #{loc} locator"
        puts "code=#{ret.code}"
        puts "message=#{ret.message}"
        puts "Body=#{ret.body}"
        next
    else
        puts "Succesfully PUT #{loc} locator"
    end
    #
    # verify by a new GET
    #
    ret = httpget(query, remote, { :key => key } )
    if ret.code.to_i != 200 then
        puts "GET error with #{loc} locator"
        puts "code=#{ret.code}"
        puts "message=#{ret.message}"
        puts "Body=#{ret.body}"
        next
    else
        puts "Succesfully GET #{loc} locator"
    end
#   puts "Body=#{ret.body}"
    #
    # Compare what we get with what we sent
    #
    puts "Compare what we sent with what we get"
    x = JSON.parse(ret.body)
    if x != event then
        puts "We get a bad event from viaFacil\nevent=#{event}\nbody=#{x}"
        exit
    else
        puts "We got the same object"
    end
    #
    # verify GET on history
    #
    ret = httpget(q, remote, { :type => event["type"], :key => key } )
    if ret.code.to_i != 200 then
        puts "GET error with #{loc} locator"
        puts "code=#{ret.code}"
        puts "message=#{ret.message}"
        puts "Body=#{ret.body}"
        next
    else
        puts "Succesfully GET on history/#{event["type"]}, body=#{ret.body}"
    end
    #
    # Make 3 modifications on public and private description then check with history
    # 
    event["public description"] = "It's very intersting stuff, must be made public"
    ret = httpput(query, remote, event, { :key => key} )
    if ret.code.to_i != 200 then
        puts "PUT error with #{loc} locator"
        puts "code=#{ret.code}"
        puts "message=#{ret.message}"
        puts "Body=#{ret.body}"
        next
    else
        puts "Succesfully PUT #{loc} locator"
    end
    event["private description"] = "Must be checked if it's real or not"
    ret = httpput(query, remote, event, { :key => key} )
    if ret.code.to_i != 200 then
        puts "PUT error with #{loc} locator"
        puts "code=#{ret.code}"
        puts "message=#{ret.message}"
        puts "Body=#{ret.body}"
        next
    else
        puts "Succesfully PUT #{loc} locator"
    end
    event["private description"] = "It's fake, it must be deleted"
    ret = httpput(query, remote, event, { :key => key} )
    if ret.code.to_i != 200 then
        puts "PUT error with #{loc} locator"
        puts "code=#{ret.code}"
        puts "message=#{ret.message}"
        puts "Body=#{ret.body}"
        next
    else
        puts "Succesfully PUT #{loc} locator"
    end
    ret = httpget(q, remote, { :type => event["type"], :key => key, "private"=> "yes" } )
    if ret.code.to_i != 200 then
        puts "GET error with #{loc} locator"
        puts "code=#{ret.code}"
        puts "message=#{ret.message}"
        puts "Body=#{ret.body}"
        next
    else
        puts "Succesfully GET on history/#{event["type"]}, body=#{ret.body}"
    end
    ret = httpget(q, remote, { :type => event["type"], :key => key, "public" => "yes" } )
    if ret.code.to_i != 200 then
        puts "GET error with #{loc} locator"
        puts "code=#{ret.code}"
        puts "message=#{ret.message}"
        puts "Body=#{ret.body}"
        next
    else
        puts "Succesfully GET on history/#{event["type"]}, body=#{ret.body}"
    end
    ret = httpget(q, remote, { :type => event["type"], :key => key } )
    if ret.code.to_i != 200 then
        puts "GET error with #{loc} locator"
        puts "code=#{ret.code}"
        puts "message=#{ret.message}"
        puts "Body=#{ret.body}"
        next
    else
        puts "Succesfully GET on history/#{event["type"]}, body=#{ret.body}"
    end
    #
    # Delete what we created
    #
    ret = httpdelete(query, remote, { :key => key } )
    if ret.code.to_i != 200 then
        puts "DEL error with #{loc} locator"
        puts "code=#{ret.code}"
        puts "message=#{ret.message}"
        puts "Body=#{ret.body}"
        next
    else
        puts "Succesfully DELETE #{loc} locator"
    end
    #
    # Ve verify that the object was deleted
    #
    ret = httpget(query, remote, { :key => key } )
    if ret.code.to_i != 200 then
        puts "Error with #{loc} locator"
        puts "code=#{ret.code}"
        puts "message=#{ret.message}"
        puts "Body=#{ret.body}"
        next
    end
     x = JSON.parse(ret.body)
     if x.empty? == true then
        puts "Previous DELETE was succesfull"
     end
}
