$CSVFile = "C:\Scripts\Utilisateurs.csv"
$CSVData = Import-CSV -Path $CSVFile -Delimiter ";" -Encoding UTF8

Foreach($Utilisateur in $CSVData){

    $UtilisateurPrenom = $Utilisateur.Prenom
    $UtilisateurNom = $Utilisateur.Nom
    $UtilisateurLogin = ($UtilisateurPrenom).Substring(0,1) + "." + $UtilisateurNom
    $UtilisateurEmail = "$UtilisateurLogin@lab.lan"
    $UtilisateurMotDePasse = "Azerty1*"
    $UtilisateurFonction = $Utilisateur.Fonction

    # Vérifier la présence de l'utilisateur dans l'AD
    if (Get-ADUser -Filter {SamAccountName -eq $UtilisateurLogin})
    {
        Write-Warning "L'identifiant $UtilisateurLogin existe déjà dans l'AD"
    }
    else
    {
        New-ADUser -Name "$UtilisateurPrenom $UtilisateurNom" `
                    -DisplayName "$UtilisateurPrenom $UtilisateurNom" `
                    -GivenName $UtilisateurPrenom `
                    -Surname $UtilisateurNom `
                    -SamAccountName ($UtilisateurLogin).ToLower() `
                    -UserPrincipalName "$UtilisateurLogin@lab.lan".ToLower() `
                    -EmailAddress ($UtilisateurEmail).ToLower() `
                    -Title $UtilisateurFonction `
                    -Path "OU=LabUSers,DC=lab,DC=lan" `
                    -AccountPassword(ConvertTo-SecureString $UtilisateurMotDePasse -AsPlainText -Force) `
                    -ChangePasswordAtLogon $false `
                    -Enabled $true

        Write-Host "Création de l'utilisateur : $UtilisateurLogin ($UtilisateurNom $UtilisateurPrenom)" -ForegroundColor Green
    }
}
