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
Fehlt `nokogiri`, wird das Gem dabei automatisch per `gem install nokogiri --no-document` nachinstalliert.

Die `./csv.rb` gibt die YAML-Dateien im CSV-Format auf der Standardausgabe aus.
Der Header wird dabei nur einmal geschrieben.
Die Spalte `Entfernung zu Neckarwestheim (km)` ist immer enthalten.

Mit `DISTANCE_FROM_NECKARWESTHEIM=1` wird die Spalte `Entfernung zu Neckarwestheim (km)` befüllt.
Ohne diese Variable bleibt die Spalte leer.
Die Berechnung nutzt Luftlinie (Haversine) auf Basis von OpenStreetMap/Nominatim-Geokodierung und speichert Ergebnisse in `geocode_cache.yml`.

Codespaces: Befehle 1:1
-----------------------

Im GitHub Codespace im Terminal diese Befehle direkt ausführen:

```bash
cd /workspaces/gemeindeverzeichnis
```

1) Nur Download der Rohdaten:

```bash
cd /workspaces/gemeindeverzeichnis
./download.sh
```

2) HTML in YAML umwandeln:

```bash
cd /workspaces/gemeindeverzeichnis
./convert.rb
```

3) Komplettes Update (pull + download + convert + commit + push):

```bash
cd /workspaces/gemeindeverzeichnis
./update.sh
```

4) Standard-CSV erzeugen:

```bash
cd /workspaces/gemeindeverzeichnis
ruby csv.rb > gemeindeverzeichnis.csv
```

5) CSV mit Distanzspalte befüllen:

```bash
cd /workspaces/gemeindeverzeichnis
DISTANCE_FROM_NECKARWESTHEIM=1 ruby csv.rb > gemeindeverzeichnis_mit_entfernung.csv
```

6) Nur Test mit begrenzten Zeilen:

```bash
cd /workspaces/gemeindeverzeichnis
LIMIT_ROWS=10 ruby csv.rb
```

Mit `DISTANCE_FROM_NECKARWESTHEIM=1` wird zusätzlich die Spalte `Entfernung zu Neckarwestheim (km)` berechnet.
Die Berechnung nutzt Luftlinie (Haversine) auf Basis von OpenStreetMap/Nominatim-Geokodierung und speichert Ergebnisse in `geocode_cache.yml`.

Beispiele:

```
ruby csv.rb > gemeindeverzeichnis.csv
DISTANCE_FROM_NECKARWESTHEIM=1 ruby csv.rb > gemeindeverzeichnis_mit_entfernung.csv
```


Spezial-Export für Rentalize
----------------------------

Für eine Liste aller Orte mit mehr als 50.000 Einwohnern im gewünschten Format (`projekt`, `ort`, `plz`, `bundesland`, `region`, `lat`, `lng`) gibt es `./rentalize_export.rb`.

Warum vorher `*.tsv` und nicht `*.csv`?
- Bisher war der Export tab-separiert (TSV), deshalb die Endung `.tsv`.
- Für Excel ist jetzt standardmäßig CSV mit Semikolon und UTF-8-BOM aktiv.

Standard (Excel-freundlich, CSV mit `;` + UTF-8-BOM):

```bash
cd /workspaces/gemeindeverzeichnis
ruby rentalize_export.rb > rentalize_orte.csv
```

Mit Koordinatenberechnung:

```bash
cd /workspaces/gemeindeverzeichnis
GEOCODE=1 ruby rentalize_export.rb > rentalize_orte.csv
```

Optional wieder als TSV:

```bash
cd /workspaces/gemeindeverzeichnis
OUTPUT_FORMAT=tsv ruby rentalize_export.rb > rentalize_orte.tsv
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

```bash
cd /workspaces/gemeindeverzeichnis
MIN_POPULATION=100000 ruby rentalize_export.rb > rentalize_orte_100k.csv
```

Excel & Umlaute
---------------

- `csv.rb` und `rentalize_export.rb` schreiben jetzt standardmäßig UTF-8 mit BOM für bessere direkte Öffnung in Excel.
- Das CSV-Trennzeichen ist `;`, was für deutsche Excel-Installationen typischerweise direkt korrekt erkannt wird.
```
MIN_POPULATION=100000 ruby rentalize_export.rb > rentalize_orte_100k.tsv
```



Lizenz
------
[WTFPL](http://sam.zoy.org/wtfpl/)
