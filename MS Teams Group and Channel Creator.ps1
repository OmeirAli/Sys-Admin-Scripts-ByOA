Import-Module MicrosoftTeams
Connect-MicrosoftTeams
$groupDisplayName = "Enter Group Name"
$mailNickName = "BGISIdeationSessionBPAccount"
$owners = @("user1@domain.com", "user2@domain.com")
$channelName = "Enter Channel Name"
$group = New-Team -DisplayName $groupDisplayName -MailNickName $mailNickName
foreach ($owner in $owners) {
    Add-TeamUser -GroupId $group.GroupId -User $owner -Role Owner
}
New-TeamChannel -GroupId $group.GroupId -DisplayName $channelName -Description "Enter Channel Description"