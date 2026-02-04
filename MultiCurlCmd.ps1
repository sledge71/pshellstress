<#
.SYNOPSIS
    Führt komplette CMD/Curl-Befehle aus einer Textdatei aus (Sequentiell oder Parallel).

.DESCRIPTION
    Liest volle Befehlszeilen (z.B. 'curl -I https://google.com') aus einer Datei.
    Führt diese über die Kommandozeile (cmd.exe) aus, um Kompatibilität mit curl-Syntax zu sichern.
    Loggt die komplette Ausgabe (Output + Fehler) in eine Datei.

.PARAMETER InputFile
    Pfad zur Textdatei mit den Befehlen.
.PARAMETER LogFile
    Pfad zur Logdatei.
.PARAMETER Parallel
    Schalter. Wenn gesetzt, werden die Befehle gleichzeitig ausgeführt (Benötigt PowerShell 7).
.PARAMETER ThrottleLimit
    Anzahl der maximal gleichzeitigen Threads im Parallel-Modus.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,

    [string]$LogFile = "log_curl.txt",

    [switch]$Parallel,

    [int]$ThrottleLimit = 5
)

# 1. Prüfung der Eingabedatei
if (-not (Test-Path $InputFile)) {
    Write-Error "Die Datei '$InputFile' wurde nicht gefunden."
    exit
}

# 2. Datei einlesen (Leere Zeilen und Kommentare ignorieren)
$commands = Get-Content $InputFile | Where-Object { $_ -and -not $_.StartsWith("#") }
$total = $commands.Count

Write-Host "Lade $total Befehle..." -ForegroundColor Cyan
if ($Parallel) { Write-Host "Modus: PARALLEL (Max: $ThrottleLimit Threads)" -ForegroundColor Yellow }
else { Write-Host "Modus: SEQUENTIELL" -ForegroundColor Yellow }

# 3. Log-Header schreiben
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"--- Neuer Lauf: $timestamp ---" | Out-File -FilePath $LogFile -Append -Encoding utf8

# 4. Definition der Ausführungslogik
# Wir nutzen cmd.exe /c, damit 'curl' als echtes Programm und nicht als PowerShell-Alias läuft.
$taskLogic = {
    param($cmdLine)
    
    $startDate = Get-Date -Format "HH:mm:ss"
    
    # Wir führen den Befehl via cmd aus, um Pipe- und Quote-Probleme zu minimieren
    # 2>&1 leitet Fehler in den gleichen Stream um, damit wir alles loggen
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "cmd.exe"
    $processInfo.Arguments = "/c $cmdLine"
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    
    $process = [System.Diagnostics.Process]::Start($processInfo)
    
    # Warte auf Abschluss und lese Output
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    
    $process.WaitForExit()
    
    # Bereite Log-Eintrag vor
    $logEntry  = "=================================================`n"
    $logEntry += "TIME:    $startDate`n"
    $logEntry += "CMD:     $cmdLine`n"
    $logEntry += "STATUS:  Exit Code $($process.ExitCode)`n"
    if ($stdout) { $logEntry += "OUTPUT:`n$stdout`n" }
    if ($stderr) { $logEntry += "ERROR:`n$stderr`n" }
    $logEntry += "=================================================`n"

    # Konsolenausgabe (kurz)
    if ($process.ExitCode -eq 0) {
        Write-Host "[$startDate] OK  : $cmdLine" -ForegroundColor Green
    } else {
        Write-Host "[$startDate] FAIL: $cmdLine" -ForegroundColor Red
    }
    
    return $logEntry
}

# 5. Ausführung (Parallel oder Sequentiell)
$results = if ($Parallel) {
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Warning "Parallel benötigt PowerShell 7+. Fallback auf sequentiell."
        foreach ($c in $commands) { & $taskLogic -cmdLine $c }
    }
    else {
        $commands | ForEach-Object -Parallel $taskLogic -ArgumentList $_ -ThrottleLimit $ThrottleLimit
    }
}
else {
    foreach ($c in $commands) {
        & $taskLogic -cmdLine $c
    }
}

# 6. Alles in die Logdatei schreiben
$results | Out-File -FilePath $LogFile -Append -Encoding utf8

Write-Host "Fertig! Logs gespeichert in '$LogFile'" -ForegroundColor Cyan