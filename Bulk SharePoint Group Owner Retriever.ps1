$UserCredential = Get-Credential
Connect-SPOService -Url "https://yourcompanydomain-admin.sharepoint.com" -Credential $UserCredential
Write-Output "Connected to SharePoint Online service."

Import-Module ActiveDirectory

$siteUrls = @(
    "https://yourdomain.sharepoint.com/sites/SPG1",
    "https://yourdomain.sharepoint.com/sites/SPG2"
)

$results = foreach ($siteUrl in $siteUrls) {
    $site = Get-SPOSite -Identity $siteUrl
    $ownerGroup = Get-SPOSiteGroup -Site $siteUrl | Where-Object { $_.Title -like "*owners*" }
    if ($ownerGroup) {
        $members = Get-SPOUser -Site $siteUrl -Group $ownerGroup.Title
        $ownerDetails = $members | ForEach-Object {
            $adUser = Get-ADUser -Filter "UserPrincipalName -eq '$($_.LoginName)'" -Properties Title, Department
            [PSCustomObject]@{
                "LoginName" = $_.LoginName
                "Title" = $adUser.Title
                "Department" = $adUser.Department
            }
        }
        [PSCustomObject]@{
            "Site URL" = $siteUrl
            "Owners" = $ownerDetails
        }
    } else {
        [PSCustomObject]@{
            "Site URL" = $siteUrl
            "Owners" = "No specific owners group found or accessible"
        }
    }
}

foreach ($result in $results) {
    Write-Output "Site URL: $($result.'Site URL')"
    foreach ($owner in $result.Owners) {
        Write-Output "LoginName: $($owner.LoginName), Title: $($owner.Title), Department: $($owner.Department)"
    }
    Write-Output "----------------------------------------"
}

Write-Output "Script execution completed. Exporting results to CSV file."


$csvData = @()
foreach ($result in $results) {
    foreach ($owner in $result.Owners) {
        $csvData += [PSCustomObject]@{
            "Site URL" = $result.'Site URL'
            "LoginName" = $owner.LoginName
            "Title" = $owner.Title
            "Department" = $owner.Department
        }
    }
    
    $csvData += [PSCustomObject]@{
        "Site URL" = ""
        "LoginName" = ""
        "Title" = ""
        "Department" = ""
    }
}

$csvData | Export-Csv -Path "enteryourpath.csv" -NoTypeInformation -Encoding UTF8
Write-Output "Finished exporting to CSV. Check the file at enteryourpath.csv."