# encoding: utf-8
require 'net/http'
require 'crack'
require 'time'
require 'yaml'

place = 'kumpula,Helsinki'
api_keys = YAML::load_file("../pidash.yml")
apikey = api_keys['fmi']

SCHEDULER.every '5m', :first_in => 0, allow_overlapping: false do |job|
  http = Net::HTTP.new('data.fmi.fi')
  # rounding forecast start time to nearest hour
  in_half = Time.at(Time.now + 1800)
  nearest_hour = Time.at(in_half - (in_half.min * 60) - in_half.sec)
  start_t = nearest_hour.iso8601.split(/\+/).first
  end_t =  Time.at(nearest_hour + 15 * 3600).iso8601.split(/\+/).first

  forecast_query = "/fmi-apikey/#{apikey}/wfs?request=getFeature&storedquery_id=fmi::forecast::hirlam::surface::point::simple&place=#{place}&timestep=60&parameters=WeatherSymbol3,temperature&starttime=#{start_t}&endtime=#{end_t}"
  measurement_query = "/fmi-apikey/#{apikey}/wfs?request=getFeature&storedquery_id=fmi::observations::weather::timevaluepair&place=#{place}&timestep=10&parameters=temperature"

  point_response = http.request(Net::HTTP::Get.new(forecast_query))
  response = http.request(Net::HTTP::Get.new(measurement_query))

  point_data = Crack::XML.parse(point_response.body)
  symbol_value = point_data['wfs:FeatureCollection']['wfs:member'].first['BsWfs:BsWfsElement']['BsWfs:ParameterValue']

  forecasts = []
  point_data['wfs:FeatureCollection']['wfs:member'].each do |k|
    if k['BsWfs:BsWfsElement']['BsWfs:ParameterName'] === 'WeatherSymbol3'
      climacon = climacon_class(k['BsWfs:BsWfsElement']['BsWfs:ParameterValue'])
      html =  '<span class="hour">' + k['BsWfs:BsWfsElement']['BsWfs:Time'][11..12] + "</span><span class='climacon #{climacon}'></span>"
      forecasts.push(html)
    elsif k['BsWfs:BsWfsElement']['BsWfs:ParameterName'] === 'temperature'
      html = forecasts.pop()
      temp = k['BsWfs:BsWfsElement']['BsWfs:ParameterValue'].to_f.round.to_s
      html +=  '<span class="temperature">' + temp + ' &deg;C</span>'
      forecasts.push(html)
    end
  end

  measurements = Crack::XML.parse(response.body)['wfs:FeatureCollection']['wfs:member']['omso:PointTimeSeriesObservation']['om:result']['wml2:MeasurementTimeseries']['wml2:point']
  celsius = '-'
  measurements.each {|point| if (point['wml2:MeasurementTVP']['wml2:value'] != 'NaN') then celsius = point['wml2:MeasurementTVP']['wml2:value'] end} 
  send_event('weather', { :temp => "#{celsius} &deg;C",
                          :title => "Kumpula",
                          :condition => forecast_string(symbol_value),
                          :forecast1 => forecasts[1],
                          :forecast2 => forecasts[4],
                          :forecast3 => forecasts[7],
                          :forecast4 => forecasts[10],
                          :forecast5 => forecasts[14],
                          :climacon => climacon_class(symbol_value)})
end

def climacon_class(weather_code)
  case weather_code.to_i
  when 1 
    'sun'
  when 2 
    'cloud sun'
  when 21 
    'drizzle'
  when 22 
    'showers'
  when 23 
    'showers'
  when 3 
    'cloud'
  when 31 
    'showers'
  when 32 
    'rain'
  when 33 
    'downpour'
  when 41 
    'snow'
  when 42 
    'snow'
  when 43 
    'snow'
  when 51 
    'snow'
  when 52 
    'snow'
  when 53 
    'snow'
  when 61 
    'lightning'
  when 62 
    'lightning'
  when 63 
    'lightning'
  when 64 
    'lightning'
  when 71 
    'sleet'
  when 72 
    'sleet'
  when 73 
    'sleet'
  end
end

def forecast_string(weather_code)
  case weather_code.to_i
  when 1 
    'Selkeää'
  when 2 
    "Puolipilvistä"
  when 21 
    'Heikkoja sadekuuroja'
  when 22 
    'Sadekuuroja'
  when 23 
    'Voimakkaita sadekuuroja'
  when 3 
    'Pilvistä'
  when 31 
    'Heikkoa vesisadetta'
  when 32 
    'Vesisadetta'
  when 33 
    'Voimakasta vesisadetta'
  when 41 
    'Heikkoja lumikuuroja'
  when 42 
    'Lumikuuroja'
  when 43 
    'Voimakkaita lumikuuroja'
  when 51 
    'Heikkoa lumisadetta'
  when 52 
    'Lumisadetta'
  when 53 
    'Voimakasta lumisadetta'
  when 61 
    'Ukkoskuuroja'
  when 62 
    'Voimakkaita ukkoskuuroja'
  when 63 
    'Ukkosta'
  when 64 
    'Voimakasta ukkosta'
  when 71 
    'Heikkoja räntäkuuroja'
  when 72 
    'Räntäkuuroja'
  when 73 
    'Voimakkaita räntäkuuroja'
  end
end
