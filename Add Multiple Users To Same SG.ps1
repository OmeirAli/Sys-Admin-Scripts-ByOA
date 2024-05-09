$groupIdentity = "yourgroupname"
$upns = @(
    "user1@domain.com",
    "user1@domain.com",
    "user1@domain.com",
    "user1@domain.com",
    "user1@domain.com",
    "user1@domain.com"
)

$samNames = $upns | ForEach-Object {
    $user = Get-ADUser -Filter "UserPrincipalName -eq '$_'" -ErrorAction SilentlyContinue
    if ($user) {
        $user.SamAccountName
    } else {
        Write-Output "User not found for UPN: $_"
    }
}
Add-ADGroupMember -Identity $groupIdentity -Members $samNames