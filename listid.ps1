# Tühi massiv/list
$numbers = @()
$numbers += 20 # Lisa element 20
$numbers += 15 # Lisa element 15
$numbers += 9  # Lisa element 9
$numbers += 54 # Lisa element 54
$numbers += 67 # Lisa element 67
$numbers += 69 # Lisa element 69

# Väljasta numbers massiivi sisu
Write-Host $numbers

# Loo nimede massiiv ja lisa nimed
$names = "Venno", "Margus", "KuusSeitse", "TungTungTungSahur", "TrallaleroTrallala", "UdinDinDinDun", "Suldar kunni", "Õie", "Àndrè"

# Väljasta nimede massiiv
Write-Host $names

# Väljasta element massiivist
Write-Host $numbers[4]   # viies element (indeks 4)
Write-Host $names[1]     # teine nimi (indeks 1)

# Väljasta listi suurus
Write-Host "Numbers listi suurus: $($numbers.Length)"
Write-Host "Names listi suurus: $($names.Length)"

# Väljasta kõik nimed massiivist "names" igaüks eraldi real
foreach($name in $names) {
    Write-Host $name
}

# Sama mis eelmine aga for-loop
Write-Host
for($x = 0; $x -lt $numbers.Length; $x++){
    Write-Host $numbers[$x]
}

# Ülesanne: Väljasta kõikide nimede pikkus kokku
$totalLength = 0
foreach($name in $names) {
    $totalLength += $name.Length
}
Write-Host "Kõigi nimede kogupikkus on: $totalLength"

# Arvuta kõikide nimede pikkus kokku, kasutades for tsüklit
$totalLength = 0
for ($i = 0; $i -lt $names.Length; $i++) {
    $totalLength += $names[$i].Length
}
Write-Host "Kõigi nimede kogupikkus on: $totalLength"

# Täishäälikud, mida arvestame
$vowels = @('a','e','i','o','u','õ','ä','ö','ü','A','E','I','O','U','Õ','Ä','Ö','Ü','à','À','è','È')

# Väljasta kõik nimed konsooli, iga nimi eraldi real, iga nime ette lisa järjekorranumber koos punkti ja tühikuga, kasutades while-loopi
$i = 0
while ($i -lt $names.Length) {
    # Arvutame täishäälikute arvu iga nime puhul
    $vowelCount = 0
    foreach ($char in $names[$i].ToCharArray()) {
        if ($vowels -contains $char) {
            $vowelCount++
        }
    }

    # Väljasta järjekorranumber, nimi ja täishäälikute arv
    Write-Host "$($i + 1). $($names[$i]) - Täishäälikute arv: $vowelCount"
    $i++
}
