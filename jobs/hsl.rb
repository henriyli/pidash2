# encoding: utf-8
require 'net/http'
require 'crack'
require 'time'
require 'yaml'
require 'uri'

uri = URI.parse('http://api.digitransit.fi/routing/v1/routers/hsl/index/graphql')
request = Net::HTTP::Post.new(uri)
request.content_type = "application/graphql"
# bus / tram / metro stop id
stop_id = 'HSL:1230101'
bike_id_1 = '139'
bike_id_2 = '138'

SCHEDULER.every '45s', :first_in => 0 do |job|
  # take it easy at night time
  night = (Time.now.hour < 5 and Time.now.hour > 23)
  if night and Time.now.min % 2 == 1
    break
  end

  # half hour window during daytime, and two hours at night time
  timerange = (Time.now.hour > 5 and Time.now.hour < 22) ? 1800 : 7200
  request.body = "query { stop(id: \"#{stop_id}\") { name stoptimesForPatterns(startTime: 0, timeRange: #{timerange}, numberOfDepartures: 4) { pattern { name } stoptimes { realtimeArrival serviceDay headsign } } } }"
  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end

  request.body = "query { bikeRentalStation(id:\"#{bike_id_1}\") { name bikesAvailable spacesAvailable } }"
  response1 = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end

  request.body = "query { bikeRentalStation(id:\"#{bike_id_2}\") { name bikesAvailable spacesAvailable } }"
  response2 = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end

  stop_result = Crack::JSON.parse(response.body)['data']['stop']
  departures = []

  stop_result['stoptimesForPatterns'].each do |line|
    name = line['pattern']['name'].split[0]
    line['stoptimes'].each do |dep|
      arrival = dep['realtimeArrival'] + dep['serviceDay']
      sign = dep['headsign'].split[0]
      departures.push({:time => arrival.to_i, :str => Time.at((Time.at(arrival.to_i) - Time.now)).min.to_s + ' min', :sign => sign, :line => name})
    end
  end
  departures = departures.sort_by {|dep| dep[:time]}

  stop_1 = {:title => stop_result['name'], :departures => departures.take(5)}

  bike_result_1 = Crack::JSON.parse(response1.body)['data']['bikeRentalStation']
  bike_1 = {:title => bike_result_1['name'], :max => bike_result_1['spacesAvailable'] + bike_result_1['bikesAvailable'], :value => bike_result_1['bikesAvailable']}

  bike_result_2 = Crack::JSON.parse(response2.body)['data']['bikeRentalStation']
  bike_2 = {:title => bike_result_2['name'], :max => bike_result_2['spacesAvailable'] + bike_result_2['bikesAvailable'], :value => bike_result_2['bikesAvailable']}

  send_event('hsl-stop-1', stop_1)
  send_event('hsl-bike-1', bike_1)
  send_event('hsl-bike-2', bike_2)
end
