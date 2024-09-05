Clear-Host
# Récupération des paramètres IPv4 des interfaces réseaux (sauf loopback)
$IPSettings = Get-NetIPAddress |
    Where-Object {($_.InterfaceAlias -notlike "*loopback*") -and ($_.AddressFamily -eq "IPv4")} |
    Select-Object -Property IPAddress, InterfaceIndex, InterfaceAlias, PrefixLength

# Récupération du statut du DHCP de l'interface réseau active
$DHCPStatus = Get-NetIPInterface |
    Where-Object {($_.InterfaceIndex -eq $IPSettings.InterfaceIndex) -and ($_.AddressFamily -eq "IPv4")} |
    Select-object -Property Dhcp

# Ajout du statut du DHCP aux paramètres IPv4 de l'interface réseau active
$Result = $IPSettings | Add-Member -NotePropertyName DHCP -NotePropertyValue $DHCPStatus.Dhcp -PassThru |
    Select-Object InterfaceAlias, IPAddress, PrefixLength, DHCP

# Vers export1.csv
"$( $Result | ConvertTo-Csv -NoTypeInformation -Delimiter ";" | Select-object -Skip 1)".Replace('"','') |
    Add-Content -Path ".\export1.csv"

$Result
