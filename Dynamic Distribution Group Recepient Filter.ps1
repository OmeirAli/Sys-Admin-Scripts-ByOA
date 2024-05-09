if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module -Name ExchangeOnlineManagement -Force
}
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName admin@example.com #replace with your Admin account here

$dynamicGroupIdentity = "enterdynamicgroupemailhere"
$dynamicGroup = Get-DynamicDistributionGroup -Identity $dynamicGroupIdentity

Write-Output "Recipient Filter: $($dynamicGroup.RecipientFilter)"
Write-Output "LDAP Recipient Filter: $($dynamicGroup.LdapRecipientFilter)"