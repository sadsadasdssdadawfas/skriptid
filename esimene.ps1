<#
Mitme realine kommentaar
Teine rida mitme realisest kommentaarist
#>
Clear

Get-Date # Hetke kuupäev ja kell

# Küsime kasutajalte kasutajanime
$username = Read-Host -Prompt "Sisesta oma xHamsteri kasutajanimi"
Write-Host $username # Näita konsooli väärtust
if ($username -eq $env:USERNAME) {
     Write-Host "Õige kasutajanimi - $username"
} else {
    Write-Host "Vale kasutajanimi"
}

# Sisesta aasta
[int]$year = Read-Host "Sisesta aasta"
Write-Host $year.GetType() # Mis tüüpi on $year
Write-Host $year # Mis väärtus sisestati
# Kas on jookseb aasta vmitte
if($year -eq(Get-Date).year) {
    Write-Host "Käesolev aasta"
} else {
    Write-Host "Mõnu muu $year"
}

<#
Küsi kasutajalt pikkust meetrites. Kui see on alla ühe meetri, siis
on Kuldar. Muul juhul "Oled sigma" :) Kasuta murdarvu varianti! 
#>

# Küsime kasutajalt pikkust meetrites
[float]$height = Read-Host "Sisesta oma pikkus meetrites"
Write-Host "Sisestatud pikkus: $height meetrit"

# Kontrollime, kas pikkus on alla ühe meetri
if ($height -lt 1.7) {
    Write-Host "Kuldar"  # Kui pikkus on alla ühe meetri
} else {
    Write-Host "Oled sigma"  # Kui pikkus on vähemalt üks meeter
}

# Väljasta pikkuse ruut (pikkus ruudus) ilma iseendaga korrutamata
$heightsquared = [math]::Pow($height, 2)
Write-Host "Pikkuse ruut: $heightsquared"

# Väljasta enda vanus sel aastal
Write-Host "$((Get-Date).year - 2008)"