$account = "enter@yourdomain.com"
$disabledOU = "OU=Disabled Users,OU=yourdomain Users,DC=yourdomain,DC=internal"
$user = Get-ADUser -Filter { UserPrincipalName -eq $account }
Disable-ADAccount -Identity $user.DistinguishedName
Move-ADObject -Identity $user.DistinguishedName -TargetPath $disabledOU