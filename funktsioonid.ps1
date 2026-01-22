Function Check-EvenOdd {
    param(
        [int]$Number
    )
    if ($Number % 2 -eq 0) {
        return "Paaris"
    } else {
        return "Paaritu"
    }
}

Function Say-Hello {
    Write-Host "Tere!"
}

Function Show-Name {
    param(
        [string]$Name = "Külaline"
    )
    Write-Host "Sinu nimi on: $Name"
}

Function Add-TwoNumbers {
    param (
        [float]$A,
        [float]$B
    )
    return ($A + $B)
}

Say-Hello
Show-Name -Name "Casper"

$name = Read-Host -Prompt "Sisesta nimi"
Show-Name -Name $name

Write-Host (Add-TwoNumbers -A 5 -B 10)

$Result = Add-TwoNumbers -A 5 -B 25
Write-Host $Result

$UserNumber = Read-Host -Prompt "Mis number on"
Write-Host (Check-EvenOdd -Number $UserNumber)
