if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "Script is not running as Administrator. Trying to restart with administrative rights..."
    Start-Process powershell.exe -ArgumentList "-File ""$PSCommandPath""" -Verb RunAs
    exit
}
Write-Host ""
Write-Warning "This script automates checking criteria for users with BGIS-Owned computers facing daily MFA requests. Review the printed sign-in logs as a final check before deciding to add the user to AAD_MFA_Enabled_BYODProblematicUsers."
Start-Sleep -Seconds 1
Write-Host ""
Write-Output "Welcome to Automated Sign In Log Checker for affected BYOD Users!"
Write-Output "By: Omeir Ali"
Write-Host ""

if (Get-Module -ListAvailable -Name AzureAD) {
    
    Write-Output "AzureAD module found. Uninstalling module..."

    Uninstall-Module -Name AzureAD -Force
}
Write-Host "AzureAD Preview is the same as AzureAD but with more cmdlets..."
Write-Host""
function Install-AzureADPreview {
    if (-not (Get-Module -ListAvailable -Name AzureADPreview)) {
        Write-Output "AzureADPreview module not found. Installing module..."
        Install-Module -Name AzureADPreview -Force
    }
}
Install-AzureADPreview
Import-Module AzureADPreview

Write-Output "Connecting to Azure AD..."
Connect-AzureAD

function Check-Exit {
    param (
        [string]$input
    )
    if ($input -eq 'exit') {
        Write-Host "Exiting script..." -ForegroundColor Yellow
        exit
    }
}
function Get-GroupMembershipDate {
    param (
        [string]$samAccountName,
        [string]$groupName
    )
    $userobj = Get-ADUser $samAccountName
    $domainControllers = @("vADFS01.apac.internal", "vADFS02.apac.internal")

    foreach ($dc in $domainControllers) {
        try {
            $groupDN = (Get-ADGroup -Identity $groupName -Server $dc).DistinguishedName
            $metadata = Get-ADReplicationAttributeMetadata $groupDN -Server $dc -ShowAllLinkedValues
            $userMetadata = $metadata | Where-Object {
                $_.AttributeName -eq 'member' -and 
                $_.AttributeValue -eq $userobj.DistinguishedName
            } | 
            Select-Object FirstOriginatingCreateTime, Object, AttributeValue

            if ($userMetadata) {
                return $userMetadata.FirstOriginatingCreateTime
            }
        } catch {
            Write-Host "Error retrieving group membership date from ${dc}: $_" -ForegroundColor Red
        }
    }
    return $null
}


$userUPNs = Read-Host -Prompt "Enter the users' email addresses/UPNs separated by commas (type 'exit' to quit)"
Check-Exit -input $userUPNs

if ($userUPNs -ne 'exit') {
    $userUPNsArray = $userUPNs -split ","
} else {
    exit
}

$affectedUsers = @()
$unaffectedUsers = @()

foreach ($userUPN in $userUPNsArray) {
    $userUPN = $userUPN.Trim()
    try {
        $user = Get-ADUser -Filter {UserPrincipalName -eq $userUPN}
        if ($null -eq $user) {
            Write-Host "User not found in Active Directory: $userUPN" -ForegroundColor Red
            continue
        } else {
            $samAccountName = $user.SamAccountName
        }
    } catch {
        Write-Host "Error retrieving user information for ${userUPN}: $_" -ForegroundColor Red
        continue
    }

    try {
        $groups = Get-ADUser -Filter {UserPrincipalName -eq $userUPN} | ForEach-Object {
            Get-ADUser -Identity $_.SamAccountName -Properties MemberOf | Select-Object -ExpandProperty MemberOf
        } | Get-ADGroup | Select-Object Name
    } catch {
        Write-Host "Error retrieving group memberships for ${userUPN}: $_" -ForegroundColor Red
        continue
    }

    $userInEnabledGroup = $groups | Where-Object { $_.Name -eq "AAD_MFA_Enabled" }
    $userInProblematicGroup = $groups | Where-Object { $_.Name -eq "AAD_MFA_Enabled_BYODProblematicUsers" }

    Write-Host ""
    Write-Host "User Group Memberships for ${userUPN}:" -ForegroundColor Yellow
    if ($userInEnabledGroup -ne $null) {
        Write-Host "- Part of AAD_MFA_Enabled" -ForegroundColor Green
    } else {
        Write-Host "- Not part of AAD_MFA_Enabled" -ForegroundColor Red
    }

    if ($userInProblematicGroup -ne $null) {
        Write-Host "- Part of AAD_MFA_Enabled_BYODProblematicUsers" -ForegroundColor Green
        $problematicGroupAddedDate = Get-GroupMembershipDate -samAccountName $samAccountName -groupName "AAD_MFA_Enabled_BYODProblematicUsers"
        if ($problematicGroupAddedDate) {
            
            Write-Host "User added to AAD_MFA_Enabled_BYODProblematicUsers on: " -NoNewline
            Write-Host "$problematicGroupAddedDate" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "User is NOT affected by daily sign-ins." -ForegroundColor Green
        Write-Host ""
        $unaffectedUsers += $userUPN
        continue
    } else {
        Write-Host "- Not part of AAD_MFA_Enabled_BYODProblematicUsers" -ForegroundColor Red
    }

    $today = Get-Date
    $sevenDaysAgo = $today.AddDays(-7)
    $sevenDaysAgoStr = $sevenDaysAgo.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $todayStr = $today.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    Write-Host ""
    Write-Host "Date range for logs: $sevenDaysAgoStr to $todayStr" -ForegroundColor Yellow

    $criteriaMetOverall = $false
    $companyOwnedDevice = $false

    Write-Host ""
    Write-Output "Checking sign-in logs for user: $userUPN from $sevenDaysAgoStr to $todayStr..."
    Write-Host ""
    Write-Output "HARD CRITERIA - Checking for Logs with 'Status: Success' Sign-In Logs ONLY"
    Write-Host ""

    try {
        $signInLogs = Get-AzureADAuditSignInLogs -Filter "userPrincipalName eq '$userUPN' and createdDateTime ge $sevenDaysAgoStr and createdDateTime le $todayStr"

        $matchingLogs = @()
        $appSignInCounts = @{}

        foreach ($log in $signInLogs) {
            $status = $log.Status
            $deviceDetail = $log.DeviceDetail
            $conditionalAccessStatus = $log.ConditionalAccessStatus

            if ($status.ErrorCode -ne 0) {
                continue
            }
            Write-Host ""
            Write-Host "Log Entry: "
            Write-Host "Request ID: $($log.Id)"
            Write-Host "Date: $($log.CreatedDateTime)"
            Write-Host "Application: $($log.AppDisplayName)"
            Write-Host "Device ID: $($log.DeviceDetail.DeviceId)"
            Write-Host "Operating System: $($log.DeviceDetail.OperatingSystem)"
            Write-Host "Browser: $($log.DeviceDetail.Browser)"
            Write-Host "Conditional Access Status: $($log.ConditionalAccessStatus)"
            Write-Host "" 

            $criteriaMet = ([string]::IsNullOrEmpty($deviceDetail.DeviceId)) -and
                           ($deviceDetail.OperatingSystem -like "Windows*") -and
                           ($conditionalAccessStatus -eq "success")

            if ($criteriaMet) {
                Write-Host "Criteria Met for this log." -ForegroundColor Green
                $matchingLogs += $log
                if ($appSignInCounts.ContainsKey($log.AppDisplayName)) {
                    $appSignInCounts[$log.AppDisplayName] += 1
                } else {
                    $appSignInCounts[$log.AppDisplayName] = 1
                }
                $criteriaMetOverall = $true
            } else {
                Write-Host "Criteria Not Met for this log." -ForegroundColor Red
            }
        }

        if ($matchingLogs.Count -eq 0) {
            Write-Host ""
            Write-Host "List of Logs that Match Criteria: 0" -ForegroundColor Yellow
        } else {
            Write-Host ""
            Write-Host "List of Logs that Match Criteria:" -ForegroundColor Yellow
            foreach ($log in $matchingLogs) {
                Write-Host "Request ID: $($log.Id)"
                Write-Host "Date: $($log.CreatedDateTime)"
                Write-Host "Application: $($log.AppDisplayName)"
                Write-Host "Device ID: $($log.DeviceDetail.DeviceId)"
                Write-Host "Operating System: $($log.DeviceDetail.OperatingSystem)"
                Write-Host "Browser: $($log.DeviceDetail.Browser)"
                Write-Host "Conditional Access Status: $($log.ConditionalAccessStatus)"
                Write-Host ""
            }
        }

        Write-Host ""
        $appSignInCountsTable = @()
        
        foreach ($app in $appSignInCounts.Keys) {
            if ($appSignInCounts[$app] -gt 1) {
                $appSignInCountsTable += [PSCustomObject]@{
                    Name = $app
                    'Total Sign-Ins' = $appSignInCounts[$app]
                }
            }
        }
        
        if ($appSignInCountsTable.Count -eq 0) {
            Write-Host "List of Applications with Sign-Ins Greater than 1: 0" -ForegroundColor Yellow
        } else {
            Write-Host "List of Applications with Sign-Ins Greater than 1: " -ForegroundColor Yellow
            $appSignInCountsTable | Sort-Object -Property 'Total Sign-Ins' -Descending | Format-Table -AutoSize
        }



        $criteria2Met = $matchingLogs | Where-Object { [string]::IsNullOrEmpty($_.DeviceDetail.DeviceId) }
        $criteria3Met = $matchingLogs | Where-Object { $_.DeviceDetail.OperatingSystem -like "Windows*" }
        $criteria4Met = $matchingLogs | Where-Object { $_.DeviceDetail.Browser -match ".*" }
        $criteria5Met = $matchingLogs | Where-Object { $_.ConditionalAccessStatus -eq "success" }

        $windowsSignInLogs = $signInLogs | Where-Object { $_.appDisplayName -eq "Windows Sign In" } | Sort-Object -Property createdDateTime -Descending

        if ($windowsSignInLogs.Count -eq 0) {
            Write-Host "No 'Windows Sign In' logs found for user: $userUPN" -ForegroundColor Red
            continue
        }

        $latestSignInLog = $windowsSignInLogs | Select-Object -First 1
        $deviceId = $latestSignInLog.DeviceDetail.DeviceId

        if ($deviceId -ne $null -and $deviceId -ne "") {
            Write-Host ""
            Write-Output "Checking if the device is BGIS Owned and Managed..."
            Write-Host ""
            $adDevice = Get-ADObject -Id "$deviceId"

            if ($adDevice) {
                Write-Output "Found device in Active Directory!"
                Write-Host ""
                Write-Host "Name: " -ForegroundColor Magenta -NoNewline
                Write-Host "$($adDevice.Name)"
                Write-Host "ObjectClass: " -ForegroundColor Magenta -NoNewline
                Write-Host "$($adDevice.ObjectClass)"
                Write-Host "ObjectGUID: " -ForegroundColor Magenta -NoNewline
                Write-Host "$($adDevice.ObjectGUID)"

                Write-Host ""
                if ($adDevice.ObjectClass -eq "computer") {
                    Write-Output "Yes, $($adDevice.Name) used by user $userUPN is a BGIS owned & managed Computer!"
                    $companyOwnedDevice = $true
                } else {
                    Write-Output "Not BGIS Owned & Managed Computer"
                }
                Write-Host ""
                $computerLastLogonDate = Get-ADComputer -Identity $adDevice.Name -Properties LastLogonDate | Select-Object -ExpandProperty LastLogonDate
                Write-Host "Computer LastLogonDate: " -ForegroundColor Magenta -NoNewline
                Write-Host "$computerLastLogonDate"
                $userLastLogonDate = Get-ADUser -Identity $samAccountName -Properties LastLogonDate | Select-Object -ExpandProperty LastLogonDate
                Write-Host "User LastLogonDate: " -ForegroundColor Magenta -NoNewline
                Write-Host "$userLastLogonDate"

            } else {
                Write-Output "No matching device found in Active Directory."
            }
        } else {
            Write-Output "Device ID is null or empty."
        }

        $criteria6Met = $companyOwnedDevice
        $criteria7Met = $matchingLogs.Count -gt 1
        Write-Host ""
        Write-Host "Criteria:" -ForegroundColor Magenta
        Write-Host "1. Device ID: Blank"
        Write-Host "2. Operating System: Any Windows OS"
        Write-Host "3. Browser: Any Web Browser"
        Write-Host "4. Conditional Access Status: Success"
        Write-Host "5. BGIS BYOD - MFA Result: Success"
        Write-Host "6. User $userUPN is using BGIS Owned and Managed Computer"
        Write-Host "7. One or more applications have sign-in frequency greater than 1"

        if ($criteriaMetOverall -and $criteria2Met -and $criteria3Met -and $criteria4Met -and $criteria5Met -and $criteria6Met -and $criteria7Met) {
            Write-Host ""
            Write-Host "User $userUPN DOES match ALL criteria 1 to 7 exactly for one or more sign in logs, check above 'List of Logs that Match Criteria' to confirm the same." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "User $userUPN DOES NOT match ALL criteria 1 to 7 perfectly/exactly for one or more sign in logs, check above 'List of Logs that Match Criteria' to confirm the same." -ForegroundColor Red
        }

    } catch {
        Write-Host "Error retrieving sign-in logs or processing data: $_" -ForegroundColor Red
    }

    Write-Host ""
    if ($criteriaMetOverall -and $criteria2Met -and $criteria3Met -and $criteria4Met -and $criteria5Met -and $criteria6Met -and $criteria7Met) {
        Write-Host "User $userUPN is affected by daily sign-ins." -ForegroundColor Red
        Write-Host ""
        $response = Read-Host -Prompt "Since user $userUPN is affected by daily sign-ins, would you like to add user to AAD_MFA_Enabled_BYODProblematicUsers?`nThis will remove user from AAD_MFA_Enabled.`nType Y (capital or lowercase for yes), N (capital or lowercase for no), A (to add all remaining affected users) and any other button to exit"

        if ($response -eq 'Y' -or $response -eq 'y') {
            Write-Host "Adding user to AAD_MFA_Enabled_BYODProblematicUsers and removing from AAD_MFA_Enabled..." -ForegroundColor Yellow
            try {
                Remove-ADGroupMember -Identity "AAD_MFA_Enabled" -Members $samAccountName -Confirm:$false
                Start-Sleep -Seconds 3
                Add-ADGroupMember -Identity "AAD_MFA_Enabled_BYODProblematicUsers" -Members $samAccountName
                Write-Host "User $userUPN has been moved to AAD_MFA_Enabled_BYODProblematicUsers." -ForegroundColor Green
                $affectedUsers += $userUPN
                Start-Sleep -Seconds 2
            } catch {
                Write-Host "Error moving user: $_" -ForegroundColor Red
            }
        } elseif ($response -eq 'N' -or $response -eq 'n') {
            Write-Host "User $userUPN not moved." -ForegroundColor Yellow
            $affectedUsers += $userUPN
        } elseif ($response -eq 'A' -or $response -eq 'a') {
            foreach ($upn in $userUPNsArray) {
                try {
                    $user = Get-ADUser -Filter {UserPrincipalName -eq $upn}
                    $samAccountName = $user.SamAccountName
                    Remove-ADGroupMember -Identity "AAD_MFA_Enabled" -Members $samAccountName -Confirm:$false
                    Add-ADGroupMember -Identity "AAD_MFA_Enabled_BYODProblematicUsers" -Members $samAccountName
                    Write-Host "User $upn has been moved to AAD_MFA_Enabled_BYODProblematicUsers." -ForegroundColor Green
                    $affectedUsers += $upn
                } catch {
                    Write-Host "Error moving user ${upn}: $_" -ForegroundColor Red
                }
            }
            break
        } else {
            Write-Host "Exiting without changes." -ForegroundColor Yellow
            break
        }
    } else {
        Write-Host "User $userUPN is NOT affected by daily sign-ins." -ForegroundColor Green
        $unaffectedUsers += $userUPN
    }
    Write-Host ""
    Write-Host "Listing all security groups for user ${userUPN}:"
    try {
        $groupsList = Get-ADUser -Filter {UserPrincipalName -eq $userUPN} | ForEach-Object {
            Get-ADUser -Identity $_.SamAccountName -Properties MemberOf | Select-Object -ExpandProperty MemberOf
        } | Get-ADGroup | Select-Object Name
        $groupsList | Format-Table -Property Name -AutoSize
    } catch {
        Write-Host "Error retrieving security groups for user ${userUPN}: $_" -ForegroundColor Red
    }
}
Write-Host "NOTE: If you pressed Y or y to add Affected User(s) to AAD_MFA_Enabled_BYODProblematicUsers above- user will be still shown as Affected User. Run Script again and user will be shown as Unaffected User. " -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary of Results:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Affected Users:" -ForegroundColor Red
$affectedUsers | ForEach-Object { Write-Host $_ -ForegroundColor Red }
Write-Host ""
Write-Host "Unaffected Users:" -ForegroundColor Green
$unaffectedUsers | ForEach-Object { Write-Host $_ -ForegroundColor Green }
Write-Host ""
Write-Host "Script successfully finished! Press Enter to exit"
Read-Host