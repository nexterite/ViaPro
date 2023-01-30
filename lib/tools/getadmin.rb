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
# Host address of machines
#
url = 'http://localhost:9292/ilayer/v1.0/'
#urls = 'https://tstbegood.loiret.fr/ilayer/v1.0/'
#
locators_with_1_key = [
['admin', { :key => "all" }],
['admin', { :key => "jams,hazard,serious_hazard" }],
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
puts "**** GET - Running admin with 1 condition on all ***"  
i = 1
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
    else
        File.open("#{i}.json","w") { |f|
            f.puts ret.body
       }
       i += 1
    end
}
