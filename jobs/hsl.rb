# encoding: utf-8
require 'net/http'
require 'crack'
require 'time'
require 'holidays'
require 'uri'

uri = URI.parse('http://api.digitransit.fi/routing/v1/routers/hsl/index/graphql')
request = Net::HTTP::Post.new(uri)
request.content_type = "application/graphql"
# bus / tram / metro stop id
config = YAML::load_file("pidash.yml")['hsl']
stop_id = config['stop_ids'].first
bike_id_1 = config['bike_station_ids'].first
bike_id_2 = config['bike_station_ids'].last

SCHEDULER.every '45s', :first_in => 0 do |job|
  time = Time.now
  hour = time.hour

  # take it easy at night time
  night = (hour < 5 and hour > 23)
  if night and time.min % 2 == 1
    break
  end

  # half hour window during daytime, and two hours at night time
  timerange = (hour > 6 and hour < 22) ? 1800 : 7200
  # extend shorter window to 45 minutes on sundays and holidays
  if (time.sunday? or Holidays.on(time.to_date, 'fi').any?) and timerange == 1800 then timerange = 2700 end

  stops = ''
  config['stop_ids'].each_with_index do |id, index|
    stops += "stop_#{index + 1}: stop(id: \"#{stop_id}\") { name stoptimesForPatterns(startTime: 0, timeRange: #{timerange}, numberOfDepartures: 4) { pattern { name } stoptimes { realtimeArrival serviceDay headsign } } } "
  end

  request.body = "query { #{stops}}"
  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end
  stop_result = Crack::JSON.parse(response.body)['data']

  stations = ''
  config['bike_station_ids'].each_with_index do |id, index|
    stations += "bike_#{index + 1}: bikeRentalStation(id:\"#{id}\") { name bikesAvailable spacesAvailable } "
  end
  request.body = "query { #{stations}}"
  bike_response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end

  stop_result.each do |id, stop|
    departures = []
    stop['stoptimesForPatterns'].each do |line|
      name = line['pattern']['name'].split[0]
      line['stoptimes'].each do |dep|
        arrival = dep['realtimeArrival'] + dep['serviceDay']
        sign = dep['headsign'].split[0]
        departures.push({:time => arrival.to_i, :str => Time.at((Time.at(arrival.to_i) - Time.now)).min.to_s + ' min', :sign => sign, :line => name})
      end
    end
    departures = departures.sort_by {|dep| dep[:time]}
    event_id = id.dup.sub! '_', '-'
    send_event(event_id, {:title => stop['name'], :departures => departures.take(5)})
  end

  bike_result = Crack::JSON.parse(bike_response.body)['data']
  bike_result.each do |id, station|
    event_id = id.dup.sub! '_', '-'
    send_event(event_id, {:title => station['name'], :max => station['spacesAvailable'] + station['bikesAvailable'], :value => station['bikesAvailable']})
  end

end
