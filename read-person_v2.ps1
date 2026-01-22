<#
Loe etteantud isikute faili ja loo neile kontod. Konto 
sisaldab kasutajanimi, e-post. 
Kasutajanimi: eesnimi.perenimi, ilma rõhumärkideta, tühiku ja sidekriipsuta
E-Post: kasutajanimi@juhe.ee
Uue faili sisu on: Eesnimi;Perenimi;Isikukood;Kasutajanimi;EPost
Keda lisada: Isikud kelle eesnimes on sidekriips või tühik. 
Kasuta .NET lugemist/kirjutamist
#>

$src = Join-Path -Path $PSScriptRoot -ChildPath "TAK20_Persons.csv"
$dst = Join-Path -Path $PSScriptRoot -ChildPath "Persons_v2.csv"
$domen = "@juhe.ee"
$header = "Eesnimi;Perenimi;Isikukood;Kasutajanimi;EPost"

function Remove-Diacritics {
    param ([String]$src = [String]::Empty)
    $normalized = $src.Normalize( [Text.NormalizationForm]::FormD )
    $sb = new-object Text.StringBuilder
    $normalized.ToCharArray() | ForEach-Object { 
        if( [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
        [void]$sb.Append($_)
        }
    }
    $sb.ToString()
}

function Get-Year {
    param(
        [string]$Date
    )
    $value = [datetime]::ParseExact($Date, "dd.MM.yyyy", 
        [System.Globalization.CultureInfo]::InvariantCulture)
    
    return $value.Year
}

# Skripti algus
# Vana faili kusttuamine
if(Test-Path $dst) {
    Remove-Item -Path $dst
    Write-Host "Kustutati fail $dst"
}

# Kirjuta uude faili päis
#cutFile -FilePath $dst -Append -InputObject $header

$lines = [System.IO.File]::ReadLines($src) | Select-Object -Skip 1

$allLines = @()
$allLines += $header

foreach($line in $lines) {
    $parts = $line.split(";")
    $firstname = $parts[0]
    $lastname = $parts[2]

    if($firstname -match '[- ]') {
        $firstname = $firstname -replace " ", ""
        $firstname = $firstname -replace "-", ""


        $username = Remove-Diacritics("$firstname.$lastname".ToLower())

        $email =$username + $domen

        $file_parts = @($parts[0], $parts[1], $parts[4], $username, $email)
        $new_line = $file_parts -join ";"
        $allLines += $new_line
    }
}    




#kirjuta massiiv fail
[System.IO.File]::WriteAllLines($dst, $allLines)
Write-Host "Valmis: $dst"
