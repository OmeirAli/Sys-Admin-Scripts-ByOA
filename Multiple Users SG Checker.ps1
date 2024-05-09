$groupName = "your groupname"
$users = @(
    "user1@domain.com",
    "user1@domain.com",
    "user1@domain.com",
    "user1@domain.com",
    "user1@domain.com",
    "user1@domain.com"
)
foreach ($user in $users) {
    $adUser = Get-ADUser -Filter "UserPrincipalName -eq '$user'" -Properties MemberOf
    if ($adUser) {
        $groups = $adUser | Select-Object -ExpandProperty MemberOf | Get-ADGroup | Select-Object -ExpandProperty Name
        if ($groups -contains $groupName) {
            Write-Output "$user YES is a member of $groupName."
        } else {
            Write-Output "$user NO is not a member of $groupName."
        }
    } else {
        Write-Output "User not found: $user."
    }
}