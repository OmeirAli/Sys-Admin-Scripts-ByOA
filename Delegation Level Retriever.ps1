function Simulate-ButtonClick {
    $originalColor = $button.BackColor
    $button.BackColor = [System.Drawing.Color]::LightGray
    Start-Sleep -Milliseconds 100
    $button.BackColor = $originalColor
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Delegation Level Retriever'
$form.Size = New-Object System.Drawing.Size(400,200)
$form.StartPosition = 'CenterScreen'

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Enter the user email address:'
$form.Controls.Add($label)

$textbox = New-Object System.Windows.Forms.TextBox
$textbox.Location = New-Object System.Drawing.Point(10,40)
$textbox.Size = New-Object System.Drawing.Size(365,20)
$textbox.Text = "@apac.bgis.com"
$form.Controls.Add($textbox)

$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(10,70)
$button.Size = New-Object System.Drawing.Size(100,23)
$button.Text = 'Retrieve'
$form.Controls.Add($button)

$form.AcceptButton = $button

$resultLabel = New-Object System.Windows.Forms.Label
$resultLabel.Location = New-Object System.Drawing.Point(10,100)
$resultLabel.Size = New-Object System.Drawing.Size(380,50)
$form.Controls.Add($resultLabel)

$button.Add_Click({
    Simulate-ButtonClick
    $email = $textbox.Text

    $searcher = New-Object DirectoryServices.DirectorySearcher([ADSI]"")
    $searcher.Filter = "(mail=$email)"
    $result = $searcher.FindOne()

    if ($result -ne $null) {
        $delegationLevel = $result.GetDirectoryEntry().Properties["extensionAttribute3"].Value
        $resultLabel.Text = "Delegation Level: $delegationLevel"
    } else {
        $resultLabel.Text = "User not found or error retrieving information."
    }
})

$form.ShowDialog()
