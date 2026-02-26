#!/usr/bin/env ruby
# encoding: UTF-8

require 'nokogiri'
require 'yaml'
require 'fileutils'

INPUT_PATTERNS = [
  'html/*.html',
  'html/*.htm',
  'html/*.{html,htm}',
  'HTML/*.html',
  'HTML/*.htm',
  'HTML/*.{html,htm}'
].freeze

input_files = INPUT_PATTERNS.flat_map { |pattern| Dir.glob(pattern, File::FNM_EXTGLOB) }.uniq.sort

if input_files.empty?
  warn "Keine HTML-Dateien gefunden. Erwartet z. B. html/*.html"
  exit 1
end

# Daten-Verzeichnis anlegen und leeren
FileUtils.mkdir_p('data')
Dir.glob('data/*.yaml').each { |path| File.delete(path) }

processed_tables = 0
written_files = 0

input_files.each do |file|
  html = File.open(file, 'r:iso-8859-1', &:read)

  # Die einzige große Tabelle in einzelne Tabellen je Gemeinde umwandeln
  html.gsub!("\r</td></tr>", "\n</td></tr></table><table>")

  # HTML parsen
  doc = Nokogiri::HTML(html)

  # Tabellen durchlaufen
  doc.css('table').each do |table|
    processed_tables += 1
    data = {}

    # Zeilen durchlaufen
    table.css('tr').each do |row|
      key, value = row.css('td').map(&:text).map(&:strip)
      next if key.nil? || key.empty? || value.nil? || value.empty?

      # Zahlen umwandeln
      value = value.gsub(' ', '').to_i if key =~ /^Einwohner/
      value = value.gsub(',', '.').to_f if value.is_a?(String) && value =~ /^\d+,\d+$/

      data[key] = value
    end

    ags = data['Amtl.Gemeindeschlüssel'] || data['Amtl. Gemeindeschlüssel']
    next unless ags

    File.open("data/#{ags}.yaml", 'w') { |f| f.puts(data.to_yaml) }
    written_files += 1
  end
end

puts "Verarbeitet: #{input_files.count} HTML-Datei(en), #{processed_tables} Tabelle(n), #{written_files} YAML-Datei(en)."
