<#
.SYNOPSIS
    Genereerib juhuslikud kasutajad etteantud tekstifailidest (osa 1).
.DESCRIPTION
    1. Pakib lahti kolm_faili.zip.
    2. Loeb sisse nimed ja kirjeldused failidest Eesnimed.txt, Perenimed.txt ja Kirjeldused.txt.
    3. Genereerib 5 juhuslikku kasutajat.
    4. Loob kasutajanime (eemaldab tühikud/kriipsud, asendab täpitähed).
    5. Salvestab tulemuse CSV faili ja kuvab konsoolis lühikokkuvõtte.
#>

# --- SEADISTUSED ---
$zipFail = "kolm_faili.zip"
$csvFail = "new_users_accounts.csv"
$kasutajateArv = 5
$staatilineParool = $null # Kui soovid kindlat parooli, kirjuta see siia jutumärkidesse (nt "Parool123")

# Määrame failinimed vastavalt ülesande kirjeldusele
$failEesnimed   = "Eesnimed.txt"
$failPerenimed  = "Perenimed.txt"
$failKirjeldused = "Kirjeldused.txt"

# --- FUNKTSIOONID ---

# Funktsioon: Puhastab teksti kasutajanime jaoks (eemaldab tühikud, kriipsud, täpitähed)
function Get-CleanUsername {
    param ([string]$tekst)
    
    # Teeme kõik väiketähtedeks
    $tekst = $tekst.ToLower()
    
    # Asendustabel eesti ja vene tähemärkide jaoks (vastavalt Eesnimed.txt sisule nagu Nadežda, Õie)
    $asendused = @{
        'õ'='o'; 'ä'='a'; 'ö'='o'; 'ü'='u';
        'š'='s'; 'ž'='z'; 
        ' '=''; '-'=''; # Eemaldame tühikud ja sidekriipsud (nt Karl Kristjan -> karlkristjan)
    }

    foreach ($key in $asendused.Keys) {
        $tekst = $tekst.Replace($key, $asendused[$key])
    }

    # Eemaldame igaks juhuks kõik muud märgid, mis pole a-z, 0-9 või punkt
    $tekst = $tekst -replace '[^a-z0-9\.]', ''
    
    return $tekst
}

# Funktsioon: Genereerib juhusliku parooli (5-8 märki)
function Get-RandomPassword {
    $pikkus = Get-Random -Minimum 5 -Maximum 9 # Maximum on välistav, seega 5-8
    # Lihtsustatud märgistik parooli jaoks
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    $parool = ""
    1..$pikkus | ForEach-Object {
        $parool += $chars[(Get-Random -Maximum $chars.Length)]
    }
    return $parool
}

# --- PÕHISKRIPT ---

# 1. Zip faili lahtipakkimine
$currentPath = $PSScriptRoot
$zipPath = Join-Path $currentPath $zipFail

if (Test-Path $zipPath) {
    Write-Host "Leidsin ZIP faili, pakin lahti..." -ForegroundColor Cyan
    # -Force kirjutab failid üle, kui need juba eksisteerivad (nagu nõutud: alati uued andmed)
    Expand-Archive -Path $zipPath -DestinationPath $currentPath -Force
} else {
    Write-Warning "ZIP faili ($zipFail) ei leitud! Eeldan, et tekstifailid on juba olemas."
}

# 2. Failide sisu lugemine
try {
    # Encoding UTF8 on oluline eesti nimede (Õie, Männik) õigeks lugemiseks
    $eesnimedData = Get-Content (Join-Path $currentPath $failEesnimed) -Encoding UTF8
    $perenimedData = Get-Content (Join-Path $currentPath $failPerenimed) -Encoding UTF8
    $kirjeldusedData = Get-Content (Join-Path $currentPath $failKirjeldused) -Encoding UTF8
}
catch {
    Write-Error "Viga failide lugemisel! Veendu, et $failEesnimed, $failPerenimed ja $failKirjeldused on kaustas olemas."
    exit
}

$genereeritudKasutajad = @()

Write-Host "`nGenereerin $kasutajateArv kasutajat..." -ForegroundColor Green
Write-Host "------------------------------------------------------"

# 3. Tsükkel kasutajate loomiseks
1..$kasutajateArv | ForEach-Object {
    # Valime juhuslikud andmed massiividest
    $randEesnimi = $eesnimedData | Get-Random
    $randPerenimi = $perenimedData | Get-Random
    $randKirjeldus = $kirjeldusedData | Get-Random

    # Töötleme kasutajanime: eesnimi.perenimi (puhastatud)
    $cleanEesnimi = Get-CleanUsername -tekst $randEesnimi
    $cleanPerenimi = Get-CleanUsername -tekst $randPerenimi
    $kasutajanimi = "$cleanEesnimi.$cleanPerenimi"

    # Parool
    if ($staatilineParool) {
        $parool = $staatilineParool
    } else {
        $parool = Get-RandomPassword
    }

    # Loome objekti
    $kasutajaObj = [PSCustomObject]@{
        Eesnimi      = $randEesnimi
        Perenimi     = $randPerenimi
        Kasutajanimi = $kasutajanimi
        Parool       = $parool
        Kirjeldus    = $randKirjeldus
    }
    
    $genereeritudKasutajad += $kasutajaObj

    # Konsooli väljund (Kirjeldus max 10 märki)
    $luhikirjeldus = if ($randKirjeldus.Length -gt 10) { $randKirjeldus.Substring(0, 10) + "..." } else { $randKirjeldus }
    
    # Kuvame info konsoolis
    Write-Host "Loodud: $($kasutajaObj.Eesnimi) $($kasutajaObj.Perenimi)"
    Write-Host "  User: $($kasutajanimi) | Pass: $parool"
    Write-Host "  Info: $luhikirjeldus" -ForegroundColor DarkGray
    Write-Host ""
}

# 4. CSV loomine (üle kirjutamine)
# Delimiter semikoolon, NoTypeInformation eemaldab PS spetsiifilise päise #TYPE
$csvPath = Join-Path $currentPath $csvFail
$genereeritudKasutajad | Export-Csv -Path $csvPath -Delimiter ";" -Encoding UTF8 -NoTypeInformation

Write-Host "Valmis! Fail salvestatud: $csvFail" -ForegroundColor Cyan