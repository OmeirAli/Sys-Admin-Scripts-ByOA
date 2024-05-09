$MailboxIdentity = "enter@email.com"
$Mailbox = Get-Mailbox -Identity $MailboxIdentity | Select-Object -Property `
    DisplayName, PrimarySmtpAddress, LitigationHoldEnabled, InPlaceHolds, RetentionHoldEnabled, 
    SingleItemRecoveryEnabled, ArchiveStatus, ElcMailboxFlags, ArchiveState, 
    EndDateForRetentionHold, StartDateForRetentionHold, LitigationHoldDate, 
    LitigationHoldOwner, ComplianceTagHoldApplied, DelayHoldApplied, DelayReleaseHoldApplied, 
    LitigationHoldDuration, SCLDeleteThreshold, SCLRejectThreshold, 
    SCLQuarantineThreshold, SCLJunkThreshold, RecipientThrottlingThreshold, 
    ElcProcessingDisabled
$HoldInfo = [PSCustomObject]@{
    DisplayName = $Mailbox.DisplayName
    PrimarySmtpAddress = $Mailbox.PrimarySmtpAddress
    LitigationHold = $Mailbox.LitigationHoldEnabled
    InPlaceHolds = $Mailbox.InPlaceHolds
    RetentionHold = $Mailbox.RetentionHoldEnabled
    SingleItemRecovery = $Mailbox.SingleItemRecoveryEnabled
    ArchiveStatus = $Mailbox.ArchiveStatus
    ElcMailboxFlags = $Mailbox.ElcMailboxFlags
    ArchiveState = $Mailbox.ArchiveState
    EndDateForRetentionHold = $Mailbox.EndDateForRetentionHold
    StartDateForRetentionHold = $Mailbox.StartDateForRetentionHold
    LitigationHoldDate = $Mailbox.LitigationHoldDate
    LitigationHoldOwner = $Mailbox.LitigationHoldOwner
    ComplianceTagHoldApplied = $Mailbox.ComplianceTagHoldApplied
    DelayHoldApplied = $Mailbox.DelayHoldApplied
    DelayReleaseHoldApplied = $Mailbox.DelayReleaseHoldApplied
    LitigationHoldDuration = $Mailbox.LitigationHoldDuration
    SCLDeleteThreshold = $Mailbox.SCLDeleteThreshold
    SCLRejectThreshold = $Mailbox.SCLRejectThreshold
    SCLQuarantineThreshold = $Mailbox.SCLQuarantineThreshold
    SCLJunkThreshold = $Mailbox.SCLJunkThreshold
    RecipientThrottlingThreshold = $Mailbox.RecipientThrottlingThreshold
    ElcProcessingDisabled = $Mailbox.ElcProcessingDisabled
}
Write-Output "Current Holds Information:"
$HoldInfo | Format-List
Write-Output "Checking and disabling holds for $MailboxIdentity if needed..."
if ($Mailbox.LitigationHoldEnabled -or $Mailbox.InPlaceHolds -ne $null -or $Mailbox.RetentionHoldEnabled) {
    if ($Mailbox.LitigationHoldEnabled) {
        Set-Mailbox -Identity $MailboxIdentity -LitigationHoldEnabled $false
        Write-Output "Litigation hold disabled."
    }

    if ($Mailbox.InPlaceHolds -ne $null) {
        Set-Mailbox -Identity $MailboxIdentity -InPlaceHolds @()
        Write-Output "In-Place holds disabled."
    }

    if ($Mailbox.RetentionHoldEnabled) {
        Set-Mailbox -Identity $MailboxIdentity -RetentionHoldEnabled $false
        Write-Output "Retention hold disabled."
    }

    Write-Output "All eligible holds disabled for $MailboxIdentity."
} else {
    Write-Output "No eligible holds found for $MailboxIdentity."
}
Write-Output "Listing all mailbox folder statistics for $MailboxIdentity..."
Get-MailboxFolderStatistics $MailboxIdentity | `
sort-object @{ Expression = {$tmp = $_.FolderSize -replace ".*\((.+)bytes\)","`$1"; [uint64]$foldersize = $tmp -replace ",",""; $foldersize }; Ascending=$false } | `
ft Identity,FolderSize
if ($Mailbox.ArchiveStatus -eq "None") {
    Write-Output "Enabling archive for $MailboxIdentity..."
    Enable-Mailbox -Identity $MailboxIdentity -Archive
    Write-Output "Archive enabled."
} else {
    Write-Output "Archive already enabled for $MailboxIdentity."
}
try {
    $AutoExpandingEnabled = (Get-Mailbox -Identity $MailboxIdentity).AutoExpandingArchive
    if (-not $AutoExpandingEnabled) {
        Write-Output "Enabling auto-expanding archive for $MailboxIdentity..."
        Enable-Mailbox -Identity $MailboxIdentity -AutoExpandingArchive
        Write-Output "Auto-expanding archive enabled."
    } else {
        Write-Output "Auto-expanding archive already enabled for $MailboxIdentity."
    }
} catch {
    Write-Output "Error while checking/enabling auto-expanding archive: $_"
}
Write-Output "Starting Managed Folder Assistant for $MailboxIdentity..."
Start-ManagedFolderAssistant -Identity $MailboxIdentity
Write-Output "Managed Folder Assistant started."

Write-Output "Script execution completed."
