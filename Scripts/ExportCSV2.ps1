Clear-Host
# Récupération des paramètres IPv4 des interfaces réseaux (sauf loopback)
$IPSettings = Get-NetIPAddress |
    Where-Object {($_.InterfaceAlias -notlike "*loopback*") -and ($_.AddressFamily -eq "IPv4")} |
    Select-Object -Property IPAddress, InterfaceIndex, InterfaceAlias, PrefixLength

# Récupération du statut du DHCP de l'interface réseau active
$DHCPStatus = Get-NetIPInterface |
    Where-Object {($_.InterfaceIndex -eq $IPSettings.InterfaceIndex) -and ($_.AddressFamily -eq "IPv4")} |
    Select-Object -Property Dhcp

# Ajout du statut du DHCP aux paramètres IPv4 de l'interface réseau active
$Result = $IPSettings | Add-Member -NotePropertyName DHCP -NotePropertyValue $DHCPStatus.Dhcp -PassThru |
    Select-Object InterfaceAlias, IPAddress, PrefixLength, DHCP

# STANDARD ###
# Affichage formaté
$InterfaceAlias = $Result.InterfaceAlias
$IPAddress = $Result.IPAddress + "/" + $Result.PrefixLength
$DHCPStatus = $Result.DHCP

$DisplayMessage = @"
Nom de l'Interface  : $InterfaceAlias
Adresse IP          : $IPAddress
Statut du DHCP      : $DHCPStatus
"@

$DisplayMessage

# AVANCÉ ###
$Result | Select-Object `
    @{Name = "Type d'interface"; Expression={$_.InterfaceAlias}}, `
    @{Name = "Adresse IP"; Expression={"$($_.IPAddress)/$($_.PrefixLength)"}}, `
    @{Name = "Statut du DHCP"; Expression={$_.DHCP}} | Format-List

# Vers export2.csv
"$Result2 = "$($Result.InterfaceAlias);$($Result.IPAddress)/$($Result.PrefixLength);$($Result.DHCP)"
$Result2 | Add-Content -Path ".\export2.csv"
