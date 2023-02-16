**REST interface V1**

**Access**

If we access from the local machine we may use a local url like 

  http://localhost:9800/ilayer/v1.0/locator

where locator is describer later.
Or if we access from an external machine we may use an external url like

  https://viapro_site.eu/ilayer/v1.0/locator

where viapro_site.eu is the name of your Web site where ViaPro was installed.

External calls must be verified at some point before passing to ilayer. In our example Nginx perfoms a basic authentication.

Remark: 
If the result is empty then ilayer will return a 200 code and an empty Json bloc {}.

**Locators**

**Weather information objects**

Current weather information objects are: current weather, forecasted weather, weather alerts, air quality

           Current weather

- GET http:://localhost/ilayer/v1.0/cweather
    Get current weather for all cities within a specific area
- GET http:://localhost/ilayer/v1.0/cweather?city=mycity
    Get current weather for the city mycity

           Forecasted weather

- GET http:://localhost/ilayer/v1.0/fweather?city=mycity
    Get current forecasted weather for the city mycity

           Weather alerts

- GET http:://localhost/ilayer/v1.0/aweather
    Get all weather alerts
- GET http:://localhost/ilayer/v1.0/aweather?city=mycity 
    Get current weather for the city mycity

           Air quality

- GET http:://localhost/ilayer/v1.0/aquality
    Get air quality for all cities
- GET http:://localhost/ilayer/v1.0/aquality?city=mycity
    Get air quality for the city mycity

**Road information objects**

Current road information objects are: car poooling, parking places, bicycles parking areas

           Car pooling areas

- GET http:://localhost/ilayer/v1.0/careas
    Get all car pooling areas from the region

           Parking places

- GET http:://localhost/ilayer/v1.0/parking
    Get parking information for Orelans parkings

           Bicycles parking areas

- GET http:://localhost/ilayer/v1.0/bparking
    Get all bicycles parking areas from the region

**Road disruption objects**

Current road disruption objects are: road works, road closure, traffic jam, flood, accident, hazard, serious gazard, landslide, technological risk, attack, market, local event

           Road works

- GET http://localhost/ilayer/v1.0/disruption/roadworks
    Get all road works from the region
- POST http://localhost/ilayer/v1.0/disruption/roadworks
    Create a new roadworks
- PUT http://localhost/ilayer/v1.0/disruption/roadworks?key=val
    Modify roadworks with key val
- DEL http://localhost/ilayer/v1.0/disruption/roadworks?key=val
    Delete roadworks with key val

           Road closure

- GET http://localhost/ilayer/v1.0/idisruption/roadclosure
    Get all road closure
- POST http://localhost/ilayer/v1.0/disruption/roadclosure
    Create a new roadclosure
- PUT http://localhost/ilayer/v1.0/disruption/roadclosure?key=val
    Modify roadclosure with key val
- DEL http://localhost/ilayer/v1.0/disruption/roadclosure?key=val
    Delete roadclosure with key val

           Traffic jam

- GET http://localhost/ilayer/v1.0/disruption/traffic_jam
    Get all traffic_jam
- POST http://localhost/ilayer/v1.0/disruption/traffic_jam
    Create a new traffic_jam
- PUT http://localhost/ilayer/v1.0/disruption/traffic_jam?key=val
    Modify traffic_jam with key val
- DEL http://localhost/ilayer/v1.0/disruption/traffic_jam?key=val
    Delete traffic_jam with key val

           Flood

- GET http://localhost/ilayer/v1.0/disruption/flood
    Get all flood
- POST http://localhost/ilayer/v1.0/disruption/flood
    Create a new flood
- PUT http://localhost/ilayer/v1.0/disruption/flood?key=val
    Modify flood with key val
- DEL http://localhost/ilayer/v1.0/disruption/flood?key=val
    Delete flood with key val

           Accident

- GET http://localhost/ilayer/v1.0/disruption/accident
    Get all accidents
- POST http://localhost/ilayer/v1.0/disruption/accident
    Create a new accident traffic_jam
- PUT http://localhost/ilayer/v1.0/disruption/accident?key=val
    Modify accident with key val
- DEL http://localhost/ilayer/v1.0/disruption/accident?key=val
    Delete accident with key val

           Hazard

- GET http://localhost/ilayer/v1.0/disruption/hazard
    Get all hazards
- POST http://localhost/ilayer/v1.0/disruption/hazard
    Create a new hazard
- PUT http://localhost/ilayer/v1.0/disruption/hazard?key=val
    Modify hazard with key val
- DEL http://localhost/ilayer/v1.0/disruption/hazard?key=val
    Delete hazard with key val

           Animal

- GET http://localhost/ilayer/v1.0/disruption/animal
    Get all issues related to animals
- POST http://localhost/ilayer/v1.0/disruption/animal
    Create a new animal
- PUT http://localhost/ilayer/v1.0/disruption/animal?key=val
    Modify animal with key val
- DEL http://localhost/ilayer/v1.0/disruption/animal?key=val
    Delete animal with key val

           Landslide

- GET http://localhost/ilayer/v1.0/disruption/landslide
    Get all landslide
- POST http://localhost/ilayer/v1.0/disruption/landslide
    Create a new landslide
- PUT http://localhost/ilayer/v1.0/disruption/landslide?key=val
    Modify landslide with key val
- DEL http://localhost/ilayer/v1.0/disruption/landslide?key=val
    Delete landslide with key val

           Technological risk

- GET http://localhost/ilayer/v1.0/disruption/technological_risk
    Get all technological risk
- POST http://localhost/ilayer/v1.0/disruption/technological_risk
    Create a new technological_risk
- PUT http://localhost/ilayer/v1.0/disruption/technological_risk?key=val
    Modify technological_risk with key val
- DEL http://localhost/ilayer/v1.0/disruption/technological_risk?key=val
    Delete technological_risk with key val

           Attack

- GET http://localhost/ilayer/v1.0/disruption/attack
    Get all attacks
- POST http://localhost/ilayer/v1.0/disruption/attack
    Create a new attack
- PUT http://localhost/ilayer/v1.0/disruption/attack?key=val
    Modify attack with key val
- DEL http://localhost/ilayer/v1.0/disruption/attack?key=val
    Delete attack with key val

           Serious hazard

- GET http://localhost/ilayer/v1.0/disruption/serious_hazard
    Get all serious hazards
- POST http://localhost/ilayer/v1.0/disruption/serious_hazard
    Create a new serious_hazard
- PUT http://localhost/ilayer/v1.0/disruption/serious_hazard?key=val
    Modify serious_hazard with key val
- DEL http://localhost/ilayer/v1.0/disruption/serious_hazard?key=val
    Delete serious_hazard with key val

           Market

- GET http://localhost/ilayer/v1.0/disruption/market
    Get all open markets
- POST http://localhost/ilayer/v1.0/disruption/market
    Create a new market
- PUT http://localhost/ilayer/v1.0/disruption/market?key=val
    Modify market with key val
- DEL http://localhost/ilayer/v1.0/disruption/market?key=val
    Delete market with key val

           Local event

- GET http://localhost/ilayer/v1.0/disruption/local_event
    Get all open local events
- POST http://localhost/ilayer/v1.0/disruption/local_event
    Create a new local_event
- PUT http://localhost/ilayer/v1.0/disruption/local_event?key=val
    Modify local_event with key val
- DEL http://localhost/ilayer/v1.0/disruption/local_event?key=val
    Delete local_event with key val

**Behaviour**

- All GET calls returns a hash (dictionary) in JSON format
- If in a GET call the provided key points to an invalid value, the return code is 200 and the body contains an empty JSON field {}
- If successful, POST returns a body with the key value. This key may be used in further GET call and must be used in PUT and DEL calls
- In a successful PUT call the return code is 200 and the body contains the string "ok"
- If in a PUT operation the provided key points to an invalid value then the return code is 404 and the body contains the message "missing key"
- In a successful DEL operation return code is 200 and the body contains the message "ok"
- If in a DEL operation the provided key points to an invalid value then the return code is 404 and the body contains the message "missing key". This may happen also when the key is valid, get from a prior successful POST call. If it's the case this means the object was deleted by another user or system task.

           Data structure

All disruptions share the same object structure. We find the following list of fields :

    1. unique disruption number
    2. disruption type
    3. geolocation
    4. direction: from 0 to 360
    5. severity level
    6. visibility: yes, no or potential
    7. address
    8. planned start date: date & time
    9. actual start date: date & time
    10. planned end date: date & time
    11. actual start date: date & time
    12. planned duration: in seconds
    13. source : source of the data or username when done thru ViaPro
    14. short description
    15. detailed description 
    16. public description
    17. private description
    18. picture
    19. options

Remarks:

- geolocation use GPS WGS84 format for point or multi-line coordinates. You will find in our examples both forms, like {"x":3.112029,"y":48.04854} or [3.112029,48.04854] or [[1.945821776190593,47.704009111704444],[1.9458979533266902, 47.703933285938696],[1.9460383600055886,47.703778826017746]]
- planned duration, planned end date, actual start date may contain nil values
- planned duration holds the estimated duration in seconds for a given disruption
- planned start date, actual start date, planned end date and actual start date use the format YYYY-MM-DD hh:mm:ss or YYYY/MM/DD hh:mm:ss, like "2019-04-15 03:00:00" or "2019/04/15 03:00:00". The timezone used iss Europe/Paris
- direction indicates the direction, clock wise, 0° to 360°
- some fields may miss (like picture) or address
- unique disruption number is a value coming from the data collector, it is set to differentiate between different events coming from the same source type

           Values setting

When a new event is created via the REST interface, in a POST operation, the body of the operation must contain the disruption object values in JSON format. Some fields are mandatory and some not. The interface will check for every field the validity of the proposed values.

Following fields are mandatory:

"unique disruption number"
"disruption type"
"geolocation"
"source" 

If one of these fields is missing then the POST or the PUT call will fail with the following error message: "error type field is missing"
