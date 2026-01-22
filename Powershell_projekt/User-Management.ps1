<#
.SYNOPSIS
    PARANDATUD SKRIPT: Haldab kasutajaid CSV faili põhjal.
.DESCRIPTION
    1. Loeb sisse new_users_accounts.csv.
    2. Kasutab 'net user' käsku parooli aegumise seadmiseks (töökindlam).
    3. Proovib lugeda faili süsteemi vaikekodeeringuga (aitab täpitähtede puhul).
#>

# --- KONTROLL: KAS ON ADMIN? ---
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Käivita PowerShell administraatorina (Run as Administrator)!"
    exit
}

# --- SEADISTUSED ---
$csvFail = Join-Path $PSScriptRoot "new_users_accounts.csv"

if (-not (Test-Path $csvFail)) {
    Write-Error "Faili $csvFail ei leitud! Käivita enne esimene skript."
    exit
}

# MUUDATUS 1: Kasutame 'Default' encodingut, kui UTF8 tekitab probleeme.
# Kui täpitähed ikka ei toimi, proovi siin uuesti '-Encoding UTF8'
$csvAndmed = Import-Csv -Path $csvFail -Delimiter ";" -Encoding Default

function Add-UsersFromCSV {
    Write-Host "`n--- KASUTAJATE LISAMINE ---" -ForegroundColor Yellow
    
    foreach ($rida in $csvAndmed) {
        $nimi = $rida.Kasutajanimi
        $parool = $rida.Parool
        $taisnimi = "$($rida.Eesnimi) $($rida.Perenimi)"
        $kirjeldus = $rida.Kirjeldus

        # Kontrollid
        if ($nimi.Length -gt 20) {
            Write-Host "VIGA: '$nimi' liiga pikk (>20). Jätan vahele." -ForegroundColor Red
            continue
        }
        if (Get-LocalUser -Name $nimi -ErrorAction SilentlyContinue) {
            Write-Host "INFO: '$nimi' on juba olemas. Jätan vahele." -ForegroundColor DarkGray
            continue
        }
        if ($kirjeldus.Length -gt 48) {
            $kirjeldus = $kirjeldus.Substring(0, 45) + "..."
        }

        try {
            $securePassword = ConvertTo-SecureString $parool -AsPlainText -Force
            
            # MUUDATUS 2: Eemaldasin siit '-UserMustChangePassword' parameetri, mis tekitas viga.
            New-LocalUser -Name $nimi `
                          -Password $securePassword `
                          -FullName $taisnimi `
                          -Description $kirjeldus `
                          -ErrorAction Stop
            
            # Lisame Users gruppi
            Add-LocalGroupMember -Group "Users" -Member $nimi -ErrorAction SilentlyContinue

            # MUUDATUS 3: Määrame parooli vahetuse nõude vana hea 'net user' käsuga
            # See on lollikindel ja töötab igas Windowsi versioonis.
            & net user $nimi /logonpasswordchg:yes | Out-Null

            Write-Host "EDUKAS: '$nimi' ($taisnimi) lisatud." -ForegroundColor Green
        }
        catch {
            Write-Host "VIGA: '$nimi' loomine ebaõnnestus: $_" -ForegroundColor Red
        }
    }
}

function Remove-SingleUser {
    Write-Host "`n--- KASUTAJA KUSTUTAMINE ---" -ForegroundColor Yellow
    $kasutajad = Get-LocalUser | Where-Object { $_.Name -notin 'Administrator', 'Guest', 'DefaultAccount', 'WDAGUtilityAccount' }
    
    if (-not $kasutajad) { Write-Warning "Kustutatavaid kasutajaid pole."; return }

    $i = 1
    foreach ($u in $kasutajad) {
        Write-Host "[$i] $($u.Name) ($($u.FullName))"
        $i++
    }

    $valik = Read-Host "`nVali number (0 tühistamiseks)"
    if ($valik -match '^\d+$' -and $valik -gt 0 -and $valik -le $kasutajad.Count) {
        $nimi = $kasutajad[$valik - 1].Name
        try {
            Remove-LocalUser -Name $nimi -ErrorAction Stop
            Write-Host "Konto '$nimi' kustutatud." -NoNewline -ForegroundColor Green
            
            $kodukaust = "C:\Users\$nimi"
            if (Test-Path $kodukaust) {
                Remove-Item -Path $kodukaust -Recurse -Force -ErrorAction Stop
                Write-Host " Kaust kustutatud." -ForegroundColor Green
            }
        } catch { Write-Error "Viga: $_" }
    }
}

# --- MENÜÜ ---
Clear-Host
Write-Host "=== PARANDATUD KASUTAJATE HALDUS ===" -ForegroundColor Cyan
Write-Host "[1] LISA kasutajad"
Write-Host "[2] KUSTUTA kasutaja"
$v = Read-Host "Valik"
switch ($v) { "1" { Add-UsersFromCSV } "2" { Remove-SingleUser } default { exit } }