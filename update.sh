#!/bin/bash -e
# 
# Aktualisiert die Daten und commitet sie im Fall von Änderungen.
# 

source_dir="html"
target_dir="data"
remote="origin"
branch="master"

# Arbeitsverzeichnis wechseln
cd `dirname $0`

# lokales Repo aktualisieren
git pull $remote $branch

# Abhängigkeit prüfen/ggf. installieren
if ! ruby -e "require 'nokogiri'" >/dev/null 2>&1
then
	echo "Nokogiri fehlt – installiere Gem ..."
	gem install nokogiri --no-document
fi

# Download
./download.sh

# Convert
./convert.rb

# Daten geändert?
if [ -z `git status -s` ]
then
	echo Keine neuen Daten
else
	# Commit
	git add -A $target_dir
	git commit $target_dir -m "Daten aktualisiert"
	git push $remote $branch
fi

# Aufräumen
rm $source_dir/*.html
