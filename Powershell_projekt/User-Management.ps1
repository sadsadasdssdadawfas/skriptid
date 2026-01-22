<#
.SYNOPSIS
    Haldab kasutajaid CSV faili põhjal (Lisa kõik või Kustuta üks).
    Nõuab Administrator õigusi.
.DESCRIPTION
    1. Loeb sisse new_users_accounts.csv.
    2. Küsib kasutajalt tegevust:
       [1] Lisa kasutajad (Loob kasutajad, nõuab parooli vahetust, lisab Users gruppi).
       [2] Kustuta kasutaja (Kustutab konto ja C:\Users\Kustutatav kausta).
#>

# --- KONTROLL: KAS ON ADMIN? ---
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Seda skripti peab käivitama administraatori õigustes ('Run as Administrator')!"
    exit
}

# --- SEADISTUSED ---
$csvFail = Join-Path $PSScriptRoot "new_users_accounts.csv"

# Kontrollime kas CSV on olemas
if (-not (Test-Path $csvFail)) {
    Write-Error "Faili $csvFail ei leitud! Käivita enne esimene skript."
    exit
}

$csvAndmed = Import-Csv -Path $csvFail -Delimiter ";" -Encoding UTF8

# --- FUNKTSIOONID ---

function Add-UsersFromCSV {
    Write-Host "`n--- KASUTAJATE LISAMINE ---" -ForegroundColor Yellow
    
    foreach ($rida in $csvAndmed) {
        $nimi = $rida.Kasutajanimi
        $parool = $rida.Parool
        $taisnimi = "$($rida.Eesnimi) $($rida.Perenimi)"
        $kirjeldus = $rida.Kirjeldus

        # 1. Kontroll: Nime pikkus (Windowsi legacy piirang on sageli 20 märki)
        if ($nimi.Length -gt 20) {
            Write-Host "VIGA: '$nimi' - Kasutajanimi on liiga pikk (>20 märki). Jätan vahele." -ForegroundColor Red
            continue
        }

        # 2. Kontroll: Kas kasutaja on juba olemas?
        if (Get-LocalUser -Name $nimi -ErrorAction SilentlyContinue) {
            Write-Host "INFO: '$nimi' - Kasutaja on juba olemas (Duplikaat). Jätan vahele." -ForegroundColor DarkGray
            continue
        }

        # 3. Kontroll: Kirjelduse pikkus ja lühendamine
        # Windows lubab pikki kirjeldusi, aga ülesanne palus lühendamist arvestada.
        if ($kirjeldus.Length -gt 48) {
            $vanaKirjeldus = $kirjeldus
            $kirjeldus = $kirjeldus.Substring(0, 45) + "..."
            Write-Host "HOIATUS: '$nimi' - Kirjeldus oli liiga pikk. Lühendatud kujule: '$kirjeldus'" -ForegroundColor Magenta
        }

        # PROOVIME KASUTAJAT LUUA
        try {
            $securePassword = ConvertTo-SecureString $parool -AsPlainText -Force
            
            # Loome kasutaja (UserMustChangePassword tagab, et esmasel logimisel küsitakse uut parooli)
            $uusKasutaja = New-LocalUser -Name $nimi `
                                         -Password $securePassword `
                                         -FullName $taisnimi `
                                         -Description $kirjeldus `
                                         -UserMustChangePassword $true `
                                         -ErrorAction Stop
            
            # Lisame kindluse mõttes Users gruppi (vaikimisi on seal, aga nõue oli range)
            Add-LocalGroupMember -Group "Users" -Member $nimi -ErrorAction SilentlyContinue

            Write-Host "EDUKAS: '$nimi' ($taisnimi) lisatud süsteemi." -ForegroundColor Green
        }
        catch {
            Write-Host "VIGA: '$nimi' loomine ebaõnnestus. Põhjus: $_" -ForegroundColor Red
        }
    }

    # LÕPUS: Kuvame süsteemis olevad mitte-vaikimisi kasutajad
    Write-Host "`n--- SÜSTEEMIS OLEVAD KASUTAJAD (V.A VAIKIMISI) ---" -ForegroundColor Cyan
    Get-LocalUser | Where-Object { 
        $_.Enabled -and 
        $_.Name -notin 'Administrator', 'Guest', 'DefaultAccount', 'WDAGUtilityAccount' 
    } | Select-Object Name, FullName, Description | Format-Table -AutoSize
}

function Remove-SingleUser {
    Write-Host "`n--- KASUTAJA KUSTUTAMINE ---" -ForegroundColor Yellow
    
    # Küsime kõik kasutajad, v.a sisseehitatud
    $kasutajad = Get-LocalUser | Where-Object { $_.Name -notin 'Administrator', 'Guest', 'DefaultAccount', 'WDAGUtilityAccount' }
    
    if (-not $kasutajad) {
        Write-Warning "Ühtegi kustutatavat kasutajat ei leitud."
        return
    }

    # Kuvame nimekirja
    $i = 1
    foreach ($u in $kasutajad) {
        Write-Host "[$i] $($u.Name) ($($u.FullName))"
        $i++
    }

    $valik = Read-Host "`nSisesta number, keda soovid kustutada (või 0 tühistamiseks)"
    
    if ($valik -match '^\d+$' -and $valik -gt 0 -and $valik -le $kasutajad.Count) {
        $valitudKasutaja = $kasutajad[$valik - 1]
        $nimi = $valitudKasutaja.Name
        
        Write-Host "Kustutan kasutajat '$nimi'..." -NoNewline
        
        try {
            # 1. Kustuta kasutaja konto
            Remove-LocalUser -Name $nimi -ErrorAction Stop
            Write-Host " Konto kustutatud." -ForegroundColor Green -NoNewline

            # 2. Kustuta kodukaust (C:\Users\Nimi)
            $kodukaust = "C:\Users\$nimi"
            if (Test-Path $kodukaust) {
                Write-Host " Kustutan kausta $kodukaust..." -NoNewline
                Remove-Item -Path $kodukaust -Recurse -Force -ErrorAction Stop
                Write-Host " Kaust kustutatud." -ForegroundColor Green
            } else {
                Write-Host " Kodukausta ei leitud (võimalik, et kasutaja pole kunagi sisse loginud)." -ForegroundColor DarkGray
            }
        }
        catch {
            Write-Error "`nViga kustutamisel: $_"
        }
    } else {
        Write-Host "Tühistatud."
    }
}

# --- PÕHIMENÜÜ ---

Clear-Host
Write-Host "=== KASUTAJATE HALDUS ===" -ForegroundColor Cyan
Write-Host "Vali tegevus:"
Write-Host "[1] LISA kõik kasutajad failist $csvFail"
Write-Host "[2] KUSTUTA üks kasutaja nimekirjast"
Write-Host "[Q] Välju"

$tegevus = Read-Host "Sinu valik"

switch ($tegevus) {
    "1" { Add-UsersFromCSV }
    "2" { Remove-SingleUser }
    "Q" { exit }
    Default { Write-Warning "Tundmatu valik." }
}

Write-Host "`nSkript lõpetas töö."