
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Attempting to restart with administrator privileges"
    Start-Process PowerShell -ArgumentList "-ExecutionPolicy Bypass -NoExit -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

if (-not (Get-Module -ListAvailable -Name AzureAD)) {
    Write-Output "AzureAD module is not installed. Installing AzureAD module..."
    Install-Module AzureAD -Scope CurrentUser
    Import-Module AzureAD
} else {
    Write-Output "AzureAD module is already installed."
    Import-Module AzureAD
}

Connect-AzureAD

Function LogWrite {
    Param ([string]$logString)
    Write-Output $logString
    Add-Content $logFilePath -Value $logString
}

$logFilePath = "C:\Users\xoali\Desktop\AzureAD_Invitations_Log_" + (Get-Date -Format "yyyyMMddHHmmss") + ".txt"
LogWrite "Starting AzureAD Guest User Invitations Process..."

$GuestUserEmailsInput = Read-Host "Please enter the guest users' email addresses (separated by ',')"
$GuestUserEmails = $GuestUserEmailsInput -split ','

$InviteRedirectURL = "https://myapps.microsoft.com"
$InvitationMessageInfo = @{
    messageLanguage = "en"
    customizedMessageBody = "Welcome to APAC BGIS!"
}

foreach ($GuestUserEmail in $GuestUserEmails) {
    $GuestUserEmail = $GuestUserEmail.Trim()
    $existingUser = Get-AzureADUser -Filter "mail eq '$GuestUserEmail' or userPrincipalName eq '$GuestUserEmail'" -ErrorAction SilentlyContinue

    if ($existingUser) {
        LogWrite "User ($GuestUserEmail) already exists in Azure AD. Checking if the user is a guest..."
        if ($existingUser.UserType -eq "Guest") {
            LogWrite "The user ($GuestUserEmail) is already a guest."
        } else {
            LogWrite "The user ($GuestUserEmail) exists but is not a guest. UserType: $($existingUser.UserType)"
        }
    } else {
        LogWrite "No existing user found with the email $GuestUserEmail. Proceeding with the invitation..."
        try {
            $Invitation = New-AzureADMSInvitation -InvitedUserEmailAddress $GuestUserEmail -InvitedUserDisplayName "Guest User" -InviteRedirectUrl $InviteRedirectURL -InvitedUserMessageInfo $InvitationMessageInfo -SendInvitationMessage $true

            if ($Invitation) {
                LogWrite "Invitation successfully created for $GuestUserEmail. Invitation ID: $($Invitation.Id)"
                $invitedUser = Get-AzureADUser -ObjectId $Invitation.InvitedUser.Id
                if ($invitedUser.UserType -eq "Guest") {
                    LogWrite "The invited user ($GuestUserEmail) is marked as a Guest."
                } else {
                    LogWrite "The invited user ($GuestUserEmail) has not been marked as a Guest. UserType: $($invitedUser.UserType)"
                }
            } else {
                LogWrite "Failed to create the invitation for $GuestUserEmail."
            }
        } catch {
            LogWrite "Error sending the invitation to ${GuestUserEmail}: $_"
        }
    }
}

LogWrite "Script execution completed."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
