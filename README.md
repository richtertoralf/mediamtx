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
  cam56:
    source: rtsp://admin:admin@192.168.95.56:554/1/h264major
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

# datarhei restreamer
Der Restreamer ist eine Streaming-Server-Lösung mit Benutzeroberfläche um RTMP- oder SRT-Streams zu YouTube, Twitch, Facebook, Vimeo oder andere Streaming-Lösungen wie Wowza weiterzuleiten. Zusätzlich besteht die Möglichkeit, den Stream auch direkt vom Server, per RTMP oder SRT abzurufen und es gibt eine einfache Webseite, wo Besucher den den Stream direkt anschauen können.    
Hier eine schnelle Installationsvariante:  
- https://github.com/richtertoralf/datarhei_Restreamer  
  
## Quellen
- https://github.com/datarhei/restreamer
- https://datarhei.com/de/
