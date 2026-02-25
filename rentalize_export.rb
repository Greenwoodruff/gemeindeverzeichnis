#!/usr/bin/env ruby
# encoding: UTF-8

require 'yaml'
require 'csv'
require 'json'
require 'net/http'
require 'uri'

MIN_POPULATION = (ENV['MIN_POPULATION'] || '50000').to_i
PROJECT_NAME = ENV['PROJECT_NAME'] || 'Rentalize'
GEOCODE_ENABLED = ENV['GEOCODE'] == '1'
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
    request['User-Agent'] = 'gemeindeverzeichnis-rentalize-export/1.0 (kontakt: lokal)'

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

def split_plz_ort(value)
  return [nil, nil] unless value

  plz, ort = value.strip.split(' ', 2)
  [plz, ort]
end

def normalize_region(value)
  return nil unless value

  value.split(',').first.strip
end

rows = []

Dir.glob('data/*.yaml').sort.each do |file|
  yaml = YAML.load_file(file)
  population = yaml['Einwohner gesamt'].to_i
  next unless population > MIN_POPULATION

  plz, ort = split_plz_ort(yaml['PLZ Ort'])
  geocode_query = [ort, plz].compact.join(' ')
  coordinates = GEOCODE_ENABLED ? geocode_place(geocode_query) : nil

  rows << [
    PROJECT_NAME,
    ort,
    plz,
    yaml['Bundesland'],
    normalize_region(yaml['Kreisname']),
    coordinates&.first,
    coordinates&.last
  ]
end

CSV.open('/dev/stdout', 'wb', col_sep: "\t") do |csv|
  csv << %w[projekt ort plz bundesland region lat lng]
  rows.each { |row| csv << row }
end

save_geocode_cache if GEOCODE_ENABLED
