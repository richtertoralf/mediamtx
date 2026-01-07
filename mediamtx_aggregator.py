#!/usr/bin/env python3

#!/usr/bin/env python3
"""
Beispielskript zur Abfrage der MediaMTX-HTTP-API.

- liest aktive Paths (/v3/paths/list)
- liest aktive SRT-Verbindungen (/v3/srtconns/list)
- verknüpft beide Datensätze über den Path-Namen
- aggregiert Stream- und Transportmetriken (Bytes, Reader, RTT, Bitraten)
- schreibt das Ergebnis als JSON nach /tmp/mediamtx_streams.json

Gedacht als einfache Grundlage für Monitoring, Debugging
oder die Weiterverarbeitung in Dashboards.
Nicht notwendig für den Betrieb von MediaMTX.
"""


import requests
import json

# Hole die Paths-Liste
paths_resp = requests.get("http://localhost:9997/v3/paths/list")
paths_resp.raise_for_status()
paths = paths_resp.json()

# Hole die SRT-Streams-Liste
srt_resp = requests.get("http://localhost:9997/v3/srtconns/list")
srt_resp.raise_for_status()
srtconns = srt_resp.json()

aggregated = []

for path in paths.get("items", []):
    name = path.get("name")
    source_type = path.get("source", {}).get("type", "unknown")
    tracks = path.get("tracks", [])
    bytes_received = path.get("bytesReceived", 0)
    readers = len(path.get("readers", []))

    entry = {
        "name": name,
        "sourceType": source_type,
        "tracks": tracks,
        "bytesReceived": bytes_received,
        "readers": readers,
    }

    if source_type == "srtConn":
        # suche in den SRT-Daten den passenden Eintrag zum Path-Namen
        srt_data = next((s for s in srtconns.get("items", []) if s.get("path") == name), None)
        if srt_data:
            entry.update({
                "rtt": srt_data.get("msRTT"),
                "recvRateMbps": srt_data.get("mbpsReceiveRate"),
                "linkCapacityMbps": srt_data.get("mbpsLinkCapacity"),
            })
    aggregated.append(entry)

# JSON speichern
with open("/tmp/mediamtx_streams.json", "w") as f:
    json.dump(aggregated, f, indent=2)

print("✅ Aggregiertes JSON wurde in /tmp/mediamtx_streams.json gespeichert.")
