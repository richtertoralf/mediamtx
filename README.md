Dieses Repository entstand zu einer Zeit, in der rtsp-simple-server gerade zu mediamtx weiterentwickelt wurde. Für meine eigenen Streaming‑Workflows war das ein interessanter Moment, denn ich arbeitete damals viel mit RTSP‑basierten PTZ‑Überwachungskameras, die wir für Sport‑Livestreaming eingesetzt haben. Diese Kameras liefern robuste Streams, aber ausschließlich über RTSP – und mussten daher in andere Protokolle wie SRT, RTMP oder HLS überführt werden.

Bevor es MediaMTX gab, haben wir unseren Streaming‑Server selbst gebaut: mit nginx + rtmp‑Modul, ffmpeg und eigenen SRT‑Pipelines, teilweise speziell für den Raspberry Pi kompiliert. Inzwischen gibt es in der Open‑Source‑Welt deutlich ausgereiftere Werkzeuge. MediaMTX ist eines davon, ebenso wie der datarhei Restreamer. Dieses Repository dokumentiert meine frühen Tests und Konfigurationen, um zu verstehen, wie sich MediaMTX in solche Workflows integrieren lässt und welche Möglichkeiten sich daraus ergeben.

## Inhalt dieses Repositories

Dieses Repository enthält praxisnahe Hilfsskripte und Konfigurationsbeispiele rund um den Einsatz von MediaMTX im Alltag:

### cloud-config
Beispiel für eine cloud-init-Konfiguration, die einen einfachen Nginx-Webserver bereitstellt.
Gedacht als schneller Viewer für MediaMTX-WebRTC- oder HLS-Streams (z. B. innerhalb eines VPNs).

### mediamtx_aggregator.py
Python-Skript zur Abfrage der MediaMTX-HTTP-API.
Aggregiert Informationen zu aktiven Paths und SRT-Verbindungen (RTT, Empfangsrate, Link-Kapazität)
und speichert diese konsolidiert als JSON – geeignet als Basis für eigenes Monitoring.

### showActivePaths_table.sh
Bash-Skript zur tabellarischen Anzeige aller aktiven MediaMTX-Paths
(Quelle, Tracks, empfangene/gesendete Bytes, Reader).

### srt-data-table.sh
Interaktive Terminal-Übersicht über aktive SRT-Publish-Verbindungen inklusive
Verbindungsstatus, RTT und Datenraten – hilfreich zur Live-Diagnose bei Events.

Die Skripte sind bewusst einfach gehalten, lesen ausschließlich die MediaMTX-API
und greifen nicht in den laufenden Betrieb ein.
Sie dienen als Werkzeuge, Beispiele und Ausgangspunkt für eigene Automatisierung oder Überwachung.

## Weiterführendes Monitoring

Für ein dauerhaftes, webbasiertes Monitoring von MediaMTX gibt es ein separates Projekt von mir:

👉 MediaMTX Monitor
https://github.com/richtertoralf/mediamtxMonitor

Der MediaMTX Monitor baut auf der MediaMTX-API auf und stellt die Informationen zentral im Browser dar – ohne direkte API-Zugriffe durch Clients.

Unterschied zu den Skripten in diesem Repository:

Die hier enthaltenen Skripte sind CLI-Tools & Beispiele (ad-hoc, terminalbasiert).

MediaMTX Monitor ist ein persistenter Monitoring-Dienst mit Web-Dashboard, JSON-API und Systemmetriken.

Geeignet, wenn:

Streams dauerhaft überwacht werden sollen

mehrere Personen Zugriff auf Status & Metriken benötigen


# mediamtx
MediaMTX (ehemals rtsp-simple-server ) ist ein gebrauchsfertiger und unabhängiger Echtzeit-Medienserver und Medien-Proxy, der das Veröffentlichen, Lesen, Proxyen und Aufzeichnen von Video- und Audiostreams ermöglicht. Er ist als „Medienrouter“ ohne GUI konzipiert, der Medienströme von einem Ende zum anderen weiterleitet. 

## Quelle
- https://github.com/bluenviron/mediamtx

## Installation
Download der Binärdateien, z.B.:
```
# Version prüfen !
wget https://github.com/bluenviron/mediamtx/releases/download/v1.3.0/mediamtx_v1.3.0_linux_arm64v8.tar.gz
```
Entpacken:
```
tar -xzvf mediamtx_v1.3.0_linux_arm64v8.tar.gz
```
Verschieben:
```
sudo mv mediamtx /usr/local/bin/
sudo mv mediamtx.yml /usr/local/etc/
```
### Konfiguration
#### Portverwendung
Diese Ports müssen in der Firewall je nach Verwendung und Konfiguration frei gegeben werden. Standartports sind je nach Protokoll:
|Protokoll                                  | Port | Art   |
|:---|:---:|:---:|
| RTSP (Real Time Streaming Protocol)         | 8554 | TCP   |
| HTTP für WebRTC (Web Real-Time Communication)| 8889 | TCP   |
| HTTP für HLS (HTTP Live Streaming)           | 8888 | TCP   |
| SRT (Secure Reliable Transport)             | 8890 | UDP   |
| RTMP (Real-Time Messaging Protocol)          | 1935 | TCP   |
| UDP für RTSP (Real Time Streaming Protocol) | 8189 | UDP   |
#### Konfigurationsdatei
Die solltest du jetzt hier finden:
```
/usr/local/etc/mediamtx.yml
```
Damit nicht irgendjemand Streams über den Server veröffentlichen kann, sollte ein Passwort gesetzt werden. Das kann z.B. so erfolgen:
```
# Default path settings
# Settings in "pathDefaults" are applied anywhere,
# unless they are overridden in "paths".
pathDefaults:
  publishUser: myuser
  publishPass: mypass
```
### Nutzungsbeispiele - Streams zum Server "pushen"
An den Stellen, wo im Folgenden "localhost" steht, sollte jeweils die IP des mediamtx-Servers eingetragen werden.
#### SRT-Streams zum mediamtx-Server schicken
Die Sender, z.B. HDMI-Encoder oder Smartphones (mit Larix Broadcaster App) oder RaspberryPis, senden den Stream als "caller" zum Server. "mystream" im folgenden Beispiel ist ein selbsgewählter Name, z.B. "Encoder61".
```
srt://localhost:8890?streamid=publish:mystream&pkt_size=1316
```
##### Testbild generieren und per SRT zum Server pushen
inklusive der Authentifizierung mit User und Passwort
siehe letzte Zeile
```
ffmpeg \
  -loglevel info \
  -f lavfi -i testsrc \
  -f lavfi -i sine=frequency=1000 \
  -filter_complex "[0:v]scale=1920:1080,format=yuv420p[v];[1:a]anull[aout]" \
  -map "[v]" -map "[aout]" \
  -r 25 -vcodec libx264 -profile:v baseline -pix_fmt yuv420p -b:v 1000k \
  -c:a mp3 -b:a 160k -ar 44100 \
  -f mpegts \
  -y 'srt://xxx.xxx.xxx.xxx:8890?streamid=publish:testbild:user:password&pkt_size=1316'
```

#### RTMP-Streams zum Server schicken
Der Sender, z.B. OBS-Studio oder eine Drohne senden einen Stream zum Server.
```
rtmp://localhost/mystream
```
Besser ist es, die eingebaute Authentifizierung zu nutzen. Falls die Authentifizierung aktiviert ist, können Anmeldeinformationen mithilfe der Abfrageparameter `user` und `pass` an den Server übergeben werden. Dies geschieht in der Konfigurationsdatei: /usr/local/etc/mediamtx.yml
```
rtmp://localhost/mystream?user=myuser&pass=mypass
```
#### WebRTC-Streams von OBS Studio (seit Version 30.0) zum mediamtx-Server schicken
```
Plattform: WHIP
Server: http://localhost:8889/obs-14/whip?user=myuser&pass=mypass
```
#### RTSP-Stream einer IP-Kamera holen
Das nutze ich, um von IP-Kameras im lokalen Netzwerk die RTSP-Streams zu holen. Anschließens kann ich sie mir z.B. per WebRTC via Browserquelle in OBS Studio mit sehr geringer Verzögerung ansehen.
```
sudo nano /usr/local/etc/mediamtx.yml
```
Am Ende der Konfigurationsdatei, im Abschnitt `Path settings` z.B. das Folgende einfügen:
```
paths:
  cam55:
    source: rtsp://admin:admin@192.168.95.55:554/1/h264major
  cam56:
    source: rtsp://admin:admin@192.168.95.56:554/1/h264major
```
### Nutzungsbeispiele - Streams vom Server holen
#### Streams vom Server holen und in einem Browser anzeigen oder als Browser-Quelle in OBS einbinden
Ich nutze gern WebRTC, da ich mit diesem Protokoll aktuell die geringsten Latenzen habe.
```
http://localhost:8889/mystream
```
weitere Varianten:
```
weitere Alternativen, z.B. als **Medienquelle** in OBS Studio eingebunden, sind,
SRT:
srt://localhost:8890?streamid=read:mystream
RTSP:
rtsp://localhost:8554/mystream
RTMP:
rtmp://localhost/mystream
und HLS als **Browserquelle**:
http://localhost:8888/mystream
```
#### weitere Beispiele
gibt es hier: https://github.com/bluenviron/mediamtx

## systemd Dienst einrichten
Service einrichten:
```
sudo tee /etc/systemd/system/mediamtx.service >/dev/null << EOF
[Unit]
Wants=network.target
[Service]
ExecStart=/usr/local/bin/mediamtx /usr/local/etc/mediamtx.yml
[Install]
WantedBy=multi-user.target
EOF
```
Einschalten und Starten:
```
sudo systemctl daemon-reload
sudo systemctl enable mediamtx
sudo systemctl start mediamtx
```
## simple Webseite
Mit dem mediamtx-Server kannst du dir jetzt, dank WebRTC und iframe, ganz einfach eine Webseite bauen, auf der deine Streams zu sehen sind. Im folgenden Beispiel verwende ich private IP-Adressen für ein lokales Netzwerk:  
```
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            margin: 0;
            padding: 0;
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(500px, 1fr));
            grid-gap: 10px;
        }
        iframe {
            width: 100%;
            height: 300px;
            border: 1px solid #ccc;
        }
    </style>
    <title>WebRTC+iframe</title>
</head>
<body>
    <iframe src="http://172.16.90.15:8889/cam55" scrolling="no"></iframe>
    <iframe src="http://172.16.90.15:8889/cam56" scrolling="no"></iframe>
    <iframe src="http://172.16.90.15:8889/cam57" scrolling="no"></iframe>
    <iframe src="http://172.16.90.15:8889/cam58" scrolling="no"></iframe>
</body>
</html>
```

## MediaMTX API & Monitoring (optional)

Neben dem eigentlichen Stream-Routing bietet MediaMTX eine umfangreiche HTTP-API.
Diese erlaubt es, aktive Streams, Reader und SRT-Verbindungen inklusive
Transportmetriken abzufragen.

Das im Repository enthaltene Python-Skript zeigt exemplarisch,
wie sich diese Informationen automatisiert erfassen und in einem
konsolidierten JSON-Format ablegen lassen.

Gedacht ist dies als Grundlage für eigenes Monitoring,
z. B. zur Überwachung von Verbindungsqualität, Stream-Auslastung
oder für spätere Visualisierungen.


# datarhei restreamer
Der Restreamer ist eine Streaming-Server-Lösung mit Benutzeroberfläche um RTMP- oder SRT-Streams zu YouTube, Twitch, Facebook, Vimeo oder andere Streaming-Lösungen wie Wowza weiterzuleiten. Zusätzlich besteht die Möglichkeit, den Stream auch direkt vom Server, per RTMP oder SRT abzurufen und es gibt eine einfache Webseite, wo Besucher den den Stream direkt anschauen können.    
Hier eine schnelle Installationsvariante:  
- https://github.com/richtertoralf/datarhei_Restreamer  
  
## Quellen
- https://github.com/datarhei/restreamer
- https://datarhei.com/de/
