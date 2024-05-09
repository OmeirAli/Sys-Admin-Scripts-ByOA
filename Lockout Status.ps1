$Username = "yoursAMName"
Import-Module ActiveDirectory

try {
    $User = Get-ADUser -Identity $Username -Properties *

    $IsLocked = $User.LockedOut
    $BadPwdCount = $User.BadPwdCount
    $LastPwdChange = $User.PasswordLastSet
    $LastBadPwdAttempt = $User.LastBadPasswordAttempt
    $Enabled = $User.Enabled
    $LastLogonDate = $User.LastLogonDate

    Write-Output "Account Lock Status: $($IsLocked)"
    Write-Output "Bad Password Count: $($BadPwdCount)"
    Write-Output "Last Password Change: $($LastPwdChange)"
    Write-Output "Last Bad Password Attempt: $($LastBadPwdAttempt)"
    Write-Output "Account Enabled: $($Enabled)"
    Write-Output "Last Logon Date: $($LastLogonDate)"
} catch {
    Write-Error "Failed to retrieve user details. Error: $_"
}