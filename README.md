Vor ein paar Jahren haben wir unseren Streamingserver für SRT und RTSP noch selber geschrieben. Dazu haben wir ffmpeg und nginx mit dem rtmp-Modul genutzt. Um SRT zu nutzen musste ffmpeg noch extra compiliert und für den RaspberryPi optimiert werden.  Inzwischen gibt es in der OpenSource-Welt fürs Streamen von Videos richtig viele gute Tools. Eins davon ist der mediamtx Mediaserver. Ein weiteres sehr gutes Tool ist der datarhei Restreamer.

# mediamtx
mediamtx Mediaserver - SRT-/WebRTC-/RTSP-/RTMP-/LL-HLS-Medienserver und Medien-Proxy, der das Lesen, Veröffentlichen, Proxyen und Aufzeichnen von Video- und Audiostreams ermöglicht.  

## Quelle
- https://github.com/bluenviron/mediamtx

## Installation
Download der Binärdateien, z.B.:
```
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
#### RTSP-Stream einer IP-Kamera holen
```
sudo nano /usr/local/etc/mediamtx.yml
```
Am Ende der Konfigurationsdatei, im Abschnitt `Path settings` z.B. das Folgende einfügen:
```
paths:
  cam55:
    source: rtsp://admin:admin@192.168.95.55:554/1/h264major
```
## systemd
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

# datarhei restreamer
Der Restreamer ist eine Streaming-Server-Lösung mit Benutzeroberfläche um RTMP- oder SRT-Streams zu YouTube, Twitch, Facebook, Vimeo oder andere Streaming-Lösungen wie Wowza weiterzuleiten. Zusätzlich besteht die Möglichkeit, den Stream auch direkt vom Server, per RTMP oder SRT abzurufen und es gibt eine einfache Webseite, wo Besucher den den Stream direkt anschauen können.    
Hier eine schnelle Installationsvariante:  
- https://github.com/richtertoralf/datarhei_Restreamer  
  
## Quellen
- https://github.com/datarhei/restreamer
- https://datarhei.com/de/
