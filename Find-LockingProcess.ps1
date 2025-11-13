# ===========================
# find-lockingprocess.ps1
# ===========================

# dieses script sucht nach allen prozessen, die eine bestimmte datei (z. b. dll, exe) geladen haben
# anschließend kann man optional einen dieser prozesse direkt beenden
# das script muss mit administratorrechten ausgeführt werden, um auf alle prozessmodule zugreifen zu können


# titelzeile zur orientierung ausgeben
write-host "🔍 interaktives tool: datei -> prozesszuordnung" -foregroundcolor cyan
write-host ""

# benutzer nach suchbegriff fragen
$filePattern = read-host "bitte gib den (teil-)namen der datei ein, z.b. oosesh.dll"

# prüfen, ob der benutzer etwas eingegeben hat
if ([string]::isnullorwhitespace($filePattern)) {
    write-host "❌ kein dateiname eingegeben. abbruch." -foregroundcolor red
    exit
}

write-host ""
write-host "⏳ suche nach prozessen, die *$filePattern* geladen haben..." -foregroundcolor yellow
write-host ""

# ergebnisse werden in einer liste gespeichert
$results = @()

# alle laufenden prozesse abrufen
foreach ($p in get-process -erroraction silentlycontinue) {
    try {
        # jeder prozess kann mehrere module (dlls, komponenten) geladen haben
        foreach ($m in $p.modules) {
            # wenn der dateiname des moduls dem suchmuster entspricht, wird ein eintrag erstellt
            if ($m.filename -like "*$filePattern*") {
                $results += [pscustomobject]@{
                    processname = $p.processname
                    pid         = $p.id
                    filename    = $m.filename
                }
            }
        }
    } catch {
        # falls der zugriff auf bestimmte systemprozesse verweigert wird, ignorieren wir das
    }
}

# prüfen, ob überhaupt ergebnisse gefunden wurden
if ($results.count -eq 0) {
    write-host "✅ keine prozesse gefunden, die $filePattern verwenden." -foregroundcolor green
    exit
}

# falls ergebnisse vorhanden sind, diese tabellarisch anzeigen
write-host "⚙️  folgende prozesse verwenden '$filePattern':" -foregroundcolor cyan
$results | format-table -autosize

write-host ""
# den benutzer fragen, ob er einen prozess beenden möchte
$killChoice = read-host "❓ möchtest du einen dieser prozesse beenden? (j/n)"

# wenn der benutzer ja sagt
if ($killChoice -match '^[JjYy]') {
    # den benutzer nach der prozess-id fragen
    $pidToKill = read-host "bitte gib die prozess-id (pid) ein, die du beenden möchtest"
    try {
        # prozess beenden
        stop-process -id [int]$pidToKill -force -erroraction stop
        write-host "✅ prozess $pidToKill wurde beendet." -foregroundcolor green
    } catch {
        write-host "❌ fehler beim beenden des prozesses: $($_.exception.message)" -foregroundcolor red
    }
} else {
    # wenn nein, nichts tun
    write-host "🔸 kein prozess beendet."
}

write-host ""
write-host "fertig." -foregroundcolor cyan
