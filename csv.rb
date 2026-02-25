#!/usr/bin/env ruby
# encoding: UTF-8

require 'yaml'
require 'csv'
require 'json'
require 'net/http'
require 'uri'

NECKARWESTHEIM = [49.0423, 9.1914]
CACHE_FILE = 'geocode_cache.yml'

def geocode_cache
  @geocode_cache ||= if File.exist?(CACHE_FILE)
                       YAML.load_file(CACHE_FILE) || {}
                     else
                       {}
                     end
end

def save_geocode_cache
  File.open(CACHE_FILE, 'w') { |file| file.write(geocode_cache.to_yaml) }
end

def geocode_place(place)
  return geocode_cache[place] if geocode_cache.key?(place)

  begin
    query = URI.encode_www_form_component("#{place}, Deutschland")
    uri = URI.parse("https://nominatim.openstreetmap.org/search?q=#{query}&format=json&limit=1")

    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = 'gemeindeverzeichnis-csv-export/1.0 (kontakt: lokal)'

    response = Net::HTTP.start(uri.host, uri.port, :use_ssl => true) { |http| http.request(request) }
    result = JSON.parse(response.body)

    coordinates = if result && !result.empty?
                    [result.first['lat'].to_f, result.first['lon'].to_f]
                  else
                    nil
                  end

    geocode_cache[place] = coordinates
    sleep 1
    coordinates
  rescue StandardError => e
    warn "Geokodierung fehlgeschlagen für '#{place}': #{e.class} #{e.message}"
    geocode_cache[place] = nil
    nil
  end
end

def haversine_km(from, to)
  rad_per_deg = Math::PI / 180
  earth_radius_km = 6371

  dlat = (to[0] - from[0]) * rad_per_deg
  dlon = (to[1] - from[1]) * rad_per_deg

  a = Math.sin(dlat / 2)**2 +
      Math.cos(from[0] * rad_per_deg) * Math.cos(to[0] * rad_per_deg) *
      Math.sin(dlon / 2)**2

  c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  earth_radius_km * c
end

def distance_to_neckarwestheim(yaml)
  place = yaml['PLZ Ort'] || yaml['PLZ Gemeindenamen'] || yaml['Anschrift der Gemeinde']
  return nil unless place

  coordinates = geocode_place(place)
  return nil unless coordinates

  haversine_km(NECKARWESTHEIM, coordinates).round(2)
end

with_distance = ENV['DISTANCE_FROM_NECKARWESTHEIM'] == '1'
limit_rows = ENV['LIMIT_ROWS'] ? ENV['LIMIT_ROWS'].to_i : nil
header_written = false
rows_written = 0

CSV.open('/dev/stdout', "wb", :col_sep => ';') do |csv|
  Dir.glob("data/*.yaml").each do |file|
    yaml = YAML.load_file(file)

    unless header_written
      headers = yaml.keys.dup
      headers << 'Entfernung zu Neckarwestheim (km)'
      csv << headers
      header_written = true
    end

    values = yaml.values.dup
    values << (with_distance ? distance_to_neckarwestheim(yaml) : nil)
    csv << values
    rows_written += 1
    break if limit_rows && rows_written >= limit_rows
  end
end

save_geocode_cache if with_distance
