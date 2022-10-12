
    class EventChk

        attr_reader :error
        attr_reader :error_message

        def initialize(severity)

            @error = false

            if File.exist?(severity) == false then
                logger.fatal('Sinatra') { "Missing severity file #{severity}" }
                @error = true
                return
            end
            @severity_level = Hash.new()
            File.open(severity,'r') { |f|
                f.each_line { |line|
                    l = line.chomp!.split("=")
                    @severity_level[l[0]] = l[1]
                }
            }

        end

        def check_event(event)

            @error = false
            @error_message = nil
            #
            # receive a JSON object and returns a JSON object after verification
            #
            begin
                e = JSON.parse(event)
            rescue JSON::ParserError
                @error = true
                @error_message = "Wrong JSON format in entry param"
                return
            end

            o = Hash.new()
# 1.
            if e.has_key?("unique disruption number") == false then
                @error_message = "Missing unique disruption number"
                @error = true
                return
            end
            o["unique disruption number"] = e["unique disruption number"]
# 2.
            if e.has_key?("type") == false then
                @error_message = "Missing type"
                @error = true
                return
            end
            o["type"] = e["type"]
# 3.
            if e.has_key?("geolocation") == false then
                @error_message = "Missing geolocation"
                @error = true
                return
            end
            o["geolocation"] = e["geolocation"]
# 4.
            if e.has_key?("actual start date") == false then
                @error_message = "Missing actual start date"
                @error = true
                return
            end
            o["actual start date"] = e["actual start date"]
# 5.
            if e.has_key?("source") == false then
                @error_message = "Missing source"
                @error = true
                return
            end
            o["source"] = e["source"]
# 6.
            if e.has_key?("direction") == false then
                o["direction"] = nil
            else
                o["direction"] = e["direction"]
            end
# 7.
            if e.has_key?("severity level") == false then
                if @severity_level.has_key?[e["type"]] == true then
                    o["severity level"] = @severity_leve[e["type"]]
                else
                    o["severity level"] = 1
                end
            else
                o["severity level"] = e["severity level"]
            end
# 8.
            if e.has_key?("visibility") == false then
                o["visibility"] = 'yes'
            else
                o["visibility"] = e["visibility"]
            end
# 9.
            if e.has_key?("address") == false then
                o["address"] = nil
            else
                o["address"] = e["address"]
            end
# 10.
            if e.has_key?("planned start date") == false then
                o["planned start date"] = nil
            else
                o["planned start date"] = e["planned start date"]
            end
# 11.
            if e.has_key?("planned duration") == false then
                o["planned duration"] = 3600
            else
                o["planned duration"] = e["planned duration"]
            end
# 12.
            if e.has_key?("actual end date") == false then
                t = Time.parse(o["actual start date"])
                t += o["planned duration"].to_i
                o["actual end date"] = t.strftime("%Y-%m-%d %H:%M")
            else
                o["actual end date"] = e["actual end date"]
            end
# 13.
            if e.has_key?("planned end date") == false then
                o["planned end date"] = nil
            else
                o["planned end date"] = e["planned end date"]
            end
# 14.
            if e.has_key?("short description") == false then
                o["short description"] = nil
            else
                o["short description"] = e["short description"]
            end
# 15.
            if e.has_key?("detailed description") == false then
                o["detailed description"] = nil
            else
                o["detailed description"] = e["detailed description"]
            end
# 16.
            if e.has_key?("picture") == false then
                o["picture"] = nil
            else
                o["picture"] = e["picture"]
            end
# 17.
            if e.has_key?("private description") == false then
                o["private description"] = nil
            else
                o["private description"] = e["private description"]
            end
# 18.
            if e.has_key?("public description") == false then
                o["public description"] = nil
            else
                o["public description"] = e["public description"]
            end

            return o.to_json
        end

        def check_history(history, actual, future)

            @error = false

            begin
                x = JSON.parse(actual)
                y = JSON.parse(future)
                if history != nil then
                    h = JSON.parse(history)
                end
            rescue JSON::ParserError
                @error = true
                @error_message = "Wrong JSON format in entry param"
                return
            end
            if x["private description"] != y["private description"] then                       # we must add the new message
                pvmessage = "Modified at #{Time.now}\n#{y["private description"]}"
                if h == nil then                                                               # we never put history, create new object
                    h = { "private description" => pvmessage, "public description" => nil }
                else
                    if h["private description"] == nil then                                    # never get a privade description
                        h["private description"] = pvmessage
                    else
                        h["private description"] = h["private description"] + "\n" + pvmessage # concatenate to previous message
                    end
               end
            end
            if x["public description"] != y["public description"] then                       # we must add the new message
                pumessage = "Modified at #{Time.now}\n#{y["public description"]}"
                if h == nil then                                                               # we never put history, create new object
                    h = { "private description" => nil, "public description" => pumessage }
                else
                    if h["public description"] == nil then                                    # never get a privade description
                        h["public description"] = pumessage
                    else
                        h["public description"] = h["public description"] + "\n" + pumessage # concatenate to previous message
                    end
               end
            end
            if h != nil then
                return h.to_json
            else
                return h
            end

        end

    end
