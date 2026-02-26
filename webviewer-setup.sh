#!/usr/bin/env bash
set -euo pipefail

#
# Bash-Skript für einen sehr einfachen Web-Viewer von MediaMTX-Streams
#
# Idee:
# - Diese Maschine streamt NICHT selbst.
# - Sie zeigt nur bereits vorhandene MediaMTX-Streams in einer HTML-Seite an.
# - nginx liefert dafür nur eine statische index.html aus.
#
# Typischer Einsatz:
# - internes Monitoring
# - LAN oder VPN (z. B. WireGuard)
# - Remote-Produktion
#
# Wichtig:
# - Der Browser des Benutzers verbindet sich später DIREKT zu MediaMTX.
# - nginx ist hier nur der "Rahmen" für die Viewer-Seite.
# - Deshalb muss der Benutzer die MediaMTX-IP auch wirklich erreichen können.
#
# Nutzungsbeispiele - Streams vom Server holen
#
# Streams können direkt vom MediaMTX-Server geholt und in einem Browser
# angezeigt oder als Quelle in OBS eingebunden werden.
#
# Für Browser-Anzeige nutze ich gern WebRTC, weil ich damit aktuell
# die geringsten Latenzen habe.
#
# Typische URLs für einen Stream mit dem Namen "mystream":
#
# WebRTC im Browser:
#   http://localhost:8889/mystream
#
# HLS als Browserquelle:
#   http://localhost:8888/mystream
#
# SRT, z. B. als Medienquelle in OBS Studio:
#   srt://localhost:8890?streamid=read:mystream
#
# RTSP:
#   rtsp://localhost:8554/mystream
#
# RTMP:
#   rtmp://localhost/mystream
#
# Dieses Skript baut nur eine einfache HTML-Seite mit mehreren iframes.
# Dafür ist in der Praxis WebRTC oder HLS sinnvoll.
# SRT, RTSP und RTMP werden hier im Konfigurationsteil trotzdem mit erklärt,
# damit ein Anfänger die verschiedenen Varianten von MediaMTX an einer Stelle sieht.
#

# Dieses Skript sollte als root ausgeführt werden.
# Beispiel:
#   sudo bash webviewer-setup.sh
if [ "${EUID}" -ne 0 ]; then
  echo "Bitte als root ausführen, z. B.: sudo bash webviewer-setup.sh"
  exit 1
fi

# ------------------------------------------------------------
# Zentrale Variablen für den Viewer
# ------------------------------------------------------------
#
# Hier stehen die Werte, die man später am einfachsten ändern kann.
#
# Grundidee:
# - Ein gemeinsamer MediaMTX-Host
# - die üblichen Standard-Ports der verschiedenen Protokolle
# - eine einfache Auswahl, welches Protokoll die HTML-Seite verwenden soll
#
# Wichtiger Unterschied:
# - WebRTC und HLS sind für Browser / iframe geeignet
# - SRT, RTSP und RTMP sind eher für OBS, VLC oder andere Player gedacht
#
# Typische Beispiele für einen Stream "cam54":
#
# WebRTC:
#   http://10.10.11.108:8889/cam54
#
# HLS:
#   http://10.10.11.108:8888/cam54
#
# SRT:
#   srt://10.10.11.108:8890?streamid=read:cam54
#
# RTSP:
#   rtsp://10.10.11.108:8554/cam54
#
# RTMP:
#   rtmp://10.10.11.108/cam54
#
# Welche Variante soll die HTML-Seite verwenden?
# Für Browser sinnvoll:
#   VIEW_PROTOCOL="webrtc"
# oder
#   VIEW_PROTOCOL="hls"
#
MEDIAMTX_HOST="10.10.11.108"

WEBRTC_PORT="8889"
HLS_PORT="8888"
SRT_PORT="8890"
RTSP_PORT="8554"
RTMP_PORT="1935"

VIEW_PROTOCOL="webrtc"

# Stream-Namen / Pfade
# Im MediaMTX-Kontext ist der Stream-Name hier gleichzeitig der Pfad.
STREAMS=(
  "cam54"
  "cam55"
  "cam56"
  "testpattern-clock"
)

# ------------------------------------------------------------
# Aus dem gewählten Protokoll die Basis-URL für die HTML-Seite bauen
# ------------------------------------------------------------
#
# Die HTML-Seite kann nur Browser-taugliche Varianten sinnvoll verwenden.
# Deshalb erlauben wir hier nur:
# - webrtc
# - hls
#
case "${VIEW_PROTOCOL}" in
  webrtc)
    VIEW_BASE_URL="http://${MEDIAMTX_HOST}:${WEBRTC_PORT}"
    ;;
  hls)
    VIEW_BASE_URL="http://${MEDIAMTX_HOST}:${HLS_PORT}"
    ;;
  *)
    echo "Ungültiges VIEW_PROTOCOL: ${VIEW_PROTOCOL}"
    echo "Erlaubt sind nur: webrtc oder hls"
    exit 1
    ;;
esac

# Paketlisten aktualisieren, damit die Installation sauber läuft
apt-get update

# Benötigtes Paket:
# - nginx: einfacher Webserver für die HTML-Seite
apt-get install -y nginx

# ------------------------------------------------------------
# NGINX-Konfiguration
# ------------------------------------------------------------
# nginx liefert nur Dateien aus /var/www/html aus.
# Dort wird später die index.html erzeugt.
#
cat > /etc/nginx/sites-available/webserver.conf <<'EOF'
server {
    # HTTP auf IPv4 und IPv6
    listen 80 default_server;
    listen [::]:80 default_server;

    # Verzeichnis der Webseite
    root /var/www/html;
    index index.html;

    # Catch-all: keine spezielle Domain nötig
    server_name _;

    # Statische Dateien ausliefern
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

chmod 0644 /etc/nginx/sites-available/webserver.conf

# ------------------------------------------------------------
# index.html automatisch aus den Variablen erzeugen
# ------------------------------------------------------------
#
# Warum dieser Schritt?
#
# Statt IP-Adressen, Ports und Stream-Namen fest in HTML zu schreiben,
# verwenden wir Bash-Variablen.
#
# Vorteil:
# - Host nur an einer Stelle ändern
# - Ports nur an einer Stelle ändern
# - Protokoll nur an einer Stelle ändern
# - Streams nur an einer Stelle ändern
#
# Das ist das eigentliche Prinzip dieser Lösung.
#
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="UTF-8">
  <title>MediaMTX Stream Viewer</title>
</head>
<body>
  <h1>MediaMTX Stream Viewer</h1>
  <p>Diese Seite zeigt vorhandene MediaMTX-Streams per iframe.</p>
  <p>Aktives Browser-Protokoll: ${VIEW_PROTOCOL}</p>
  <p>Basis-URL: ${VIEW_BASE_URL}</p>
EOF

for STREAM in "${STREAMS[@]}"; do
  cat >> /var/www/html/index.html <<EOF
  <h2>${STREAM}</h2>
  <iframe src="${VIEW_BASE_URL}/${STREAM}" width="640" height="360"></iframe>
EOF
done

cat >> /var/www/html/index.html <<EOF
</body>
</html>
EOF

# Besitzer des Web-Verzeichnisses sauber setzen
chown -R www-data:www-data /var/www/html

# ------------------------------------------------------------
# Webserver aktivieren
# ------------------------------------------------------------

# Standard-Seite von nginx entfernen
rm -f /etc/nginx/sites-enabled/default*

# Eigene nginx-Konfiguration aktivieren
ln -sfn /etc/nginx/sites-available/webserver.conf /etc/nginx/sites-enabled/webserver.conf

# nginx-Konfiguration testen und nur dann neu starten, wenn sie gültig ist
nginx -t && systemctl restart nginx

echo
echo "Fertig."
echo "Viewer-Seite: http://<dieser-host>/"
echo "Aktives Browser-Protokoll: ${VIEW_PROTOCOL}"
echo "Basis-URL für Browser: ${VIEW_BASE_URL}"
echo
echo "Weitere MediaMTX-Beispiele für einen Stream:"
echo "  WebRTC: http://${MEDIAMTX_HOST}:${WEBRTC_PORT}/<stream>"
echo "  HLS:    http://${MEDIAMTX_HOST}:${HLS_PORT}/<stream>"
echo "  SRT:    srt://${MEDIAMTX_HOST}:${SRT_PORT}?streamid=read:<stream>"
echo "  RTSP:   rtsp://${MEDIAMTX_HOST}:${RTSP_PORT}/<stream>"
echo "  RTMP:   rtmp://${MEDIAMTX_HOST}/<stream>"
