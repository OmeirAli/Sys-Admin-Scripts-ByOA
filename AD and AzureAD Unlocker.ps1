Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function CheckAndInstall-Module {
    param (
        [string]$moduleName
    )
    if (-not (Get-Module -ListAvailable -Name $moduleName)) {
        try {
            Install-Module -Name $moduleName -Force -Scope CurrentUser -WarningAction SilentlyContinue
            Import-Module $moduleName -WarningAction SilentlyContinue
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to install module: $moduleName. Error: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            exit
        }
    } else {
        Import-Module $moduleName -WarningAction SilentlyContinue
    }
}

CheckAndInstall-Module "AzureAD"

function Unlock-UserAccounts {
    param (
        [string]$emailAddress
    )

    if (-not ($emailAddress -match "^\S+@\S+\.\S+$")) {
        return "Invalid email address format."
    }

    $result = ""

    try {
        $searcher = New-Object DirectoryServices.DirectorySearcher([ADSI]"")
        $searcher.Filter = "(mail=$emailAddress)"
        $adUser = $searcher.FindOne()

        if ($adUser -ne $null) {
            $userEntry = $adUser.GetDirectoryEntry()
            $userEntry.psbase.InvokeSet("LockoutTime", 0)
            $userEntry.CommitChanges()
            $result += "AD account unlocked. "
        } else {
            $result += "AD user not found. "
        }
    } catch {
        $result += "Error unlocking AD account: $_ "
    }

    try {
        $azureAdConnection = Connect-AzureAD -WarningAction SilentlyContinue | Out-Null
        $azureUser = Get-AzureADUser -Filter "mail eq '$emailAddress'"
        if ($azureUser) {
            Set-AzureADUser -ObjectId $azureUser.ObjectId -AccountEnabled $true
            $result += "Azure AD account enabled."
        } else {
            $result += "Azure AD user not found."
        }
    } catch {
        $result += "Error enabling Azure AD account: $_"
    }

    return $result
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Unlock User Accounts'
$form.Size = New-Object System.Drawing.Size(300,150)
$form.StartPosition = 'CenterScreen'

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,10)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Enter the user email address:'
$form.Controls.Add($label)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10,40)
$textBox.Size = New-Object System.Drawing.Size(260,20)
$textBox.Text = '@apac.bgis.com' # Prefilled text
$form.Controls.Add($textBox)

$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(10,70)
$button.Size = New-Object System.Drawing.Size(260,30)
$button.Text = 'Unlock Account'
$button.Add_Click({
    $button.Enabled = $false

    $job = Start-Job -ScriptBlock ${function:Unlock-UserAccounts} -ArgumentList $textBox.Text

    while ($job.State -eq 'Running') {
        Start-Sleep -Seconds 1
    }

    $result = Receive-Job -Job $job

    [System.Windows.Forms.MessageBox]::Show($result, "Result", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

    $button.Enabled = $true
})


$form.Controls.Add($button)

$form.AcceptButton = $button
$form.ShowDialog()
$form.Dispose()
