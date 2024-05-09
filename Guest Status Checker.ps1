Connect-AzureAD

Function LogWrite {
    Param ([string]$logString)
    Write-Output $logString
    Add-Content $logFilePath -Value $logString
}

$logFilePath = "C:\Users\xoali\Desktop\AzureAD_Invitation_Status_Log_" + (Get-Date -Format "yyyyMMddHHmmss") + ".txt"
LogWrite "Checking AzureAD Guest User Invitation Status..."

$GuestUserEmailsInput = Read-Host "Please enter the guest users' email addresses (separated by ',')"
$GuestUserEmails = $GuestUserEmailsInput -split ','

foreach ($GuestUserEmail in $GuestUserEmails) {
    $GuestUserEmail = $GuestUserEmail.Trim()
    $invitation = Get-AzureADMSInvitation -Filter "invitedUserEmailAddress eq '$GuestUserEmail'" -ErrorAction SilentlyContinue

    if ($invitation) {
        $status = $invitation.Status
        LogWrite "Invitation status for $GuestUserEmail is $status."
    } else {
        LogWrite "No invitation found for $GuestUserEmail."
    }
}

LogWrite "Status check completed."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
