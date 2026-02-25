Gemeindeverzeichnis
===================

Das [Gemeindeverzeichnis-Informationssystem](https://www.destatis.de/DE/ZahlenFakten/LaenderRegionen/Regionales/Gemeindeverzeichnis/Gemeindeverzeichnis.html) (GV-ISys) des Statistischen Bundesamts führt jede politisch selbständige Gemeinde Deutschlands (ohne Ortsteildaten) u.a. mit den Merkmalen:

* Amtlicher Gemeindeschlüssel (AGS)
* Gemeindenamen
* Die Postleitzahl des Verwaltungssitzes der Gemeinde bzw. Stadt
* Fläche in km²
* Einwohnerzahl (insgesamt/männlich/weiblich)
* Siedlungsstrukturelle Typisierungen, wie z.B. Raumordnungsregionen oder auch EU-Stadt-Land-Gliederung

Leider bietet das Statistische Bundesamt keinen kostenlosen Download des Gemeindeverzeichnisses an.
Es kann im Excel-Format für 108,- € erworben werden. Aus diesem Grund wurde dieses freie Repository geschaffen.
Die kostenlose CSV-Datei gibt es [hier](https://github.com/downloads/digineo/gemeindeverzeichnis/gemeindeverzeichnis.csv).

Aktualisierung der Daten
------------------------

Für die Aktualisierung der Daten wird [Ruby 1.9](http://www.ruby-lang.org/) und der HTML-Parser [Nokogiri](http://rubygems.org/gems/nokogiri) benötigt.

Die `./download.sh` lädt die Suchergebnisse als HTML herunter und legt sie unter /html ab.

Die `./convert.rb` wandelt die heruntergeladenen Suchergebnisse ins [YAML](http://de.wikipedia.org/wiki/YAML)-Format um und legt sie unter /data ab.

Die `./update.sh` führt den Download und die Umwandlung durch, commitet die Änderungen und pusht diese.

Die `./csv.rb` gibt die YAML-Dateien im CSV-Format auf der Standardausgabe aus.
Der Header wird dabei nur einmal geschrieben.
Die Spalte `Entfernung zu Neckarwestheim (km)` ist immer enthalten.

Mit `DISTANCE_FROM_NECKARWESTHEIM=1` wird die Spalte `Entfernung zu Neckarwestheim (km)` befüllt.
Ohne diese Variable bleibt die Spalte leer.
Die Berechnung nutzt Luftlinie (Haversine) auf Basis von OpenStreetMap/Nominatim-Geokodierung und speichert Ergebnisse in `geocode_cache.yml`.

Beispiele:

```
ruby csv.rb > gemeindeverzeichnis.csv
DISTANCE_FROM_NECKARWESTHEIM=1 ruby csv.rb > gemeindeverzeichnis_mit_entfernung.csv
```


Spezial-Export für Rentalize
----------------------------

Für eine Liste aller Orte mit mehr als 50.000 Einwohnern im gewünschten Format (`projekt`, `ort`, `plz`, `bundesland`, `region`, `lat`, `lng`) gibt es `./rentalize_export.rb`:

```
ruby rentalize_export.rb > rentalize_orte.tsv
```

Hinweise:
- Ausgabe ist Tab-separiert (`.tsv`) und enthält den Header `projekt	ort	plz	bundesland	region	lat	lng`.
- Standardmäßig werden `lat`/`lng` nicht befüllt (leer).
- Mit `GEOCODE=1` werden `lat`/`lng` per Nominatim-Geokodierung berechnet und in `geocode_cache.yml` zwischengespeichert:

```
GEOCODE=1 ruby rentalize_export.rb > rentalize_orte.tsv
```

Optional kann die Einwohnergrenze angepasst werden:

```
MIN_POPULATION=100000 ruby rentalize_export.rb > rentalize_orte_100k.tsv
```



Lizenz
------
[WTFPL](http://sam.zoy.org/wtfpl/)
