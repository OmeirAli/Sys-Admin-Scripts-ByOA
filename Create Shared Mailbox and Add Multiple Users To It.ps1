$sharedMailboxes = @("shared@mailbox.com")
$users = @("user1@domain.com",
    "user1@domain.com",
    "user1@domain.com",
    "user1@domain.com",
    "user1@domain.com",
    "user1@domain.com")
foreach ($mailbox in $sharedMailboxes) {
    New-Mailbox -Shared -Name $mailbox -PrimarySmtpAddress $mailbox
    
    foreach ($user in $users) {
        Add-MailboxPermission -Identity $mailbox -User $user -AccessRights FullAccess -InheritanceType All
    }