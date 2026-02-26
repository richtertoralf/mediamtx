#!/usr/bin/env bash
set -euo pipefail

#
# Bash-Skript für einen einfachen MediaMTX-Web-Viewer / Monitor
#
# Idee:
# - Diese Maschine streamt NICHT selbst.
# - Sie liefert nur eine statische index.html über nginx aus.
# - Die eigentliche Logik steckt in der index.html aus dem Repository.
#
# Typischer Einsatz:
# - internes Monitoring
# - LAN oder VPN
# - Remote-Produktion
#
# Wichtig:
# - Dieses Skript erzeugt die HTML-Seite nicht mehr selbst.
# - Stattdessen wird die Datei "index.html" aus dem Repository kopiert.
# - Skript und index.html liegen im Repo flach im selben Verzeichnis.
#
# Wichtiger Zusatz für diese Monitor-Seite:
# - Die index.html fragt die MediaMTX-Control-API ab:
#     /v3/paths/list
# - Dafür muss der Zugriff auf die API ausdrücklich erlaubt sein.
# - Standardmäßig ist das oft nur für localhost freigegeben.
#
# Beispiel in /usr/local/etc/mediamtx.yml:
#
# authInternalUsers:
# - user: any
#   pass:
#   ips: ['127.0.0.1', '::1', '10.10.11.0/24']
#   permissions:
#   - action: api
#
# Nur wenn der Browser bzw. das Client-Netz Zugriff auf die API hat,
# kann die Seite die verfügbaren Streams automatisch erkennen.
#
# Beispiel:
#   mediamtx/
#   ├── webviewer-setup.sh
#   └── index.html
#
# Dadurch bleibt das Bash-Skript einfach
# und die HTML-/JavaScript-Datei kann separat gepflegt werden.
#

# Dieses Skript sollte als root ausgeführt werden.
# Beispiel:
#   sudo bash webviewer-setup.sh
if [ "${EUID}" -ne 0 ]; then
  echo "Bitte als root ausführen, z. B.: sudo bash webviewer-setup.sh"
  exit 1
fi

# ------------------------------------------------------------
# Pfade ermitteln
# ------------------------------------------------------------
#
# Das Skript bestimmt zuerst sein eigenes Verzeichnis.
# Von dort wird später die index.html kopiert.
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_INDEX="${SCRIPT_DIR}/index.html"
TARGET_INDEX="/var/www/html/index.html"

# Prüfen, ob die index.html im selben Verzeichnis vorhanden ist
if [ ! -f "${SOURCE_INDEX}" ]; then
  echo "Fehler: ${SOURCE_INDEX} nicht gefunden."
  echo "Lege webviewer-setup.sh und index.html im selben Verzeichnis ab."
  exit 1
fi

# Paketlisten aktualisieren, damit die Installation sauber läuft
apt-get update

# Benötigtes Paket:
# - nginx: einfacher Webserver für die HTML-Seite
apt-get install -y nginx

# ------------------------------------------------------------
# NGINX-Konfiguration
# ------------------------------------------------------------
# nginx liefert nur Dateien aus /var/www/html aus.
# Dort liegt später die index.html aus dem Repository.
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
# index.html aus dem Repository kopieren
# ------------------------------------------------------------
#
# Warum dieser Schritt?
#
# Früher wurde die HTML-Datei direkt im Bash-Skript erzeugt.
# Jetzt liegt sie separat im Repository.
#
# Vorteil:
# - HTML, CSS und JavaScript bleiben besser lesbar
# - Änderungen an der Webseite sind einfacher
# - das Installationsskript bleibt kurz und verständlich
#
mkdir -p /var/www/html
cp "${SOURCE_INDEX}" "${TARGET_INDEX}"

# Besitzer des Web-Verzeichnisses sauber setzen
chown -R www-data:www-data /var/www/html

# Sinnvolle Dateirechte setzen
chmod 0644 "${TARGET_INDEX}"

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
echo "Die index.html wurde kopiert nach: ${TARGET_INDEX}"
echo "Viewer-Seite: http://<dieser-host>/"
echo
echo "Wichtig:"
echo "Die Monitor-Seite benötigt Zugriff auf die MediaMTX-Control-API (/v3/paths/list)."
echo "Prüfe deshalb die Freigabe in /usr/local/etc/mediamtx.yml."
echo
echo "Wenn du die Webseite später änderst, reicht meist:"
echo "  sudo cp ${SOURCE_INDEX} ${TARGET_INDEX}"
echo "  sudo chown www-data:www-data ${TARGET_INDEX}"
