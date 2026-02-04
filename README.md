# MultiCurl-PS Runner

Ein flexibles PowerShell-Skript, um eine Liste von **vollständigen cURL-Befehlen** aus einer Textdatei auszulesen und auszuführen. Es unterstützt sowohl sequentielle als auch parallele (Multithreading) Ausführung.

## 🚀 Features

* **Parallele Ausführung:** Führt hunderte Requests gleichzeitig aus (benötigt PowerShell 7+).
* **Volle cURL-Kompatibilität:** Nutzt `cmd.exe` als Wrapper, sodass originale `curl`-Syntax (inkl. Header, POST-Daten, Flags) verwendet werden kann.
* **Detailliertes Logging:** Speichert Standard-Output (stdout) und Fehlermeldungen (stderr) sowie Statuscodes in einer Logdatei.
* **Abwärtskompatibel:** Fällt automatisch auf sequentielle Ausführung zurück, wenn PowerShell 5.1 genutzt wird.

## 📋 Voraussetzungen

* **Windows OS**
* **cURL** muss installiert und im PATH sein (Standard in Windows 10/11).
* **PowerShell 7 (Core)** für den `-Parallel` Modus (empfohlen).
* *PowerShell 5.1* reicht für den sequentiellen Modus.

## ⚙️ Installation

1.  Lade das Skript `MultiCurlCmd.ps1` herunter.
2.  Erstelle eine Textdatei (z. B. `commands.txt`) mit deinen Befehlen.

## 📖 Nutzung

### 1. Eingabedatei erstellen
Erstelle eine Datei (z. B. `commands.txt`). Schreibe pro Zeile einen kompletten curl-Befehl. Kommentare mit `#` sind erlaubt.

**Beispiel `commands.txt`:**
```text
# Health Check
curl -I [https://www.google.com](https://www.google.com)

# API Test mit Header
curl -X GET [https://httpbin.org/get](https://httpbin.org/get) -H "Accept: application/json"

# POST Request (JSON Keys müssen escaped werden!)
curl -X POST [https://httpbin.org/post](https://httpbin.org/post) -H "Content-Type: application/json" -d "{\"status\": \"active\"}"

2. Skript ausführen
Öffne ein Terminal in dem Ordner und führe das Skript aus.

Sequentiell (Nacheinander): Gut für Debugging oder wenn die Reihenfolge wichtig ist.
.\MultiCurlCmd.ps1 -InputFile commands.txt

Parallel (Gleichzeitig): Benötigt PowerShell 7+. Ideal für Lasttests oder viele Requests.
.\MultiCurlCmd.ps1 -InputFile commands.txt -Parallel -ThrottleLimit 10

📄 Logging
Die Ergebnisse werden standardmäßig in log_curl.txt gespeichert (kann mit -LogFile angepasst werden).

Beispiel Log-Output:
--- Neuer Lauf: 2023-10-27 14:00:00 ---
=================================================
TIME:    14:00:01
CMD:     curl -I [https://www.google.com](https://www.google.com)
STATUS:  Exit Code 0
OUTPUT:
HTTP/1.1 200 OK
Content-Type: text/html; charset=ISO-8859-1
...
=================================================
