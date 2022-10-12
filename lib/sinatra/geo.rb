require 'geokit'

    class GeoFinder

        attr_reader :error

        def initialize(filename, distance)

            @distance = distance
            @error = false

            if File.exist?(filename) then
                if File.open(filename, 'r') { |f|
                    y = Psych.load_stream(f)
                    @cities = y[0]
                }
            else
                @error = true
            end
        end

        def geo_locate(lat, long)

            @error = false
            from = [lat.to_f, long.to_f]

            distances = Array.new()
            @cities.each { |key,to|
                distances << [key, Geokit::GeoLoc.distance_between(from , to , {:units => :kms, :formula => :sphere} ) ]
            }
            min = distances.min { |x,y| x[1] <=> y[1] }
            city = min[0]
            dist = min[1]
            if dist < @distance then
                return city
            else
                @error = true
            end  

        end

    end
end
