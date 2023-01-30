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
#urls = 'https://trafficbegood.loiret.fr/ilayer/v1.0/'
#
locators = {
'1'=>'cweather',
'2'=>'fweather',
'3'=>'aweather',
'4'=>'aquality',
'5'=>'gstation',
'6'=>'careas',
'7'=>'bparking',
'8'=>'parking',
'9'=>'jams',
'10'=>'risk_areas',
'11'=>'disruption/roadworks',
'12'=>'disruption/roadclosure',
'13'=>'disruption/traffic_jam',
'14'=>'disruption/flood',
'15'=>'disruption/accident',
'16'=>'disruption/hazard',
'17'=>'disruption/animal',
'18'=>'disruption/landslide',
'19'=>'disruption/technological_risk',
'20'=>'disruption/attack',
'21'=>'disruption/serious_hazard',
'22'=>'disruption/market',
'23'=>'disruption/local_event'
}

r = ENV["REMOTE"]
if r == nil then
    puts "REMOTE environment variable was not set to yes or no, it will be forced to no"
    remote = false
elsif r == 'yes'  then
    remote = true
elsif r == 'no' then
    remote = false
else
    puts "Invalid value #{r} for REMOTE envirnment variable, it will be forced to yes"
    remote = true
end
puts "Available locators\n"
locators.each { |k,v|
    puts "key=#{k}\t#{v}"
}
print "Choose one locator:"
n = gets().chomp!
if locators.has_key?(n) == false then
    puts "Invalid choice, leaving"
    exit
end
puts "**** GET - getting all entries for #{locators[n]} ***"  
loc = locators[n]
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
    puts "HTTP error, leaving dump.rb"
    exit
end

puts "Succesfully locator #{loc}"
ans = JSON.parse(ret.body)
    
if ans.empty? == true then
    puts "Locator #{loc} is empty, leaving"
    exit
end

puts "There are #{ans.length} entries in #{loc}"
print "Dump (y/n):"
a = gets().chomp!
if a == 'n' then
    puts "Leaving dump.rb"
    exit
end
fname = n+".out"
print "Get key (y/n):"
b = gets().chomp!
puts "Dumping #{loc} in #{fname} file"
File.open(fname, 'w') { |f|
    ans.each { |k,v|
        if b == 'y' then
            f.puts "k=#{k} v=#{v}"
        else
            f.puts "#{v}"
        end
    }
}
