
# Credential Switcher
# Alvaro Orgaz Fuertes
# GNU GPLv3
#
# ToDo:
# - Credentials stored on the local drive are deleted after a set time. User is requested to provide again passwords which are encrypted witha new key and pin.
# - Provide a graphical representation of the current credential being used (user/admin) (green/safe, red/unsafe).
# - Display timer until timeout.
# - Generate a random KeyBase.
# - Combine both credentials in a single file.



$CredentialsFolderPath = "$env:USERPROFILE\AppData\Local\CredentialSwitcher"
$CredentialsFilePath = "$CredentialsFolderPath\Credentials.txt"
$PrivilegedCredentialsUsername = "admin"
$UnprivilegedCredentialsUsername = "user"
$NetworkShareDriveLetter = "N:"
$NetworkHost="NAS" # host name or IP address
$NetworkSharePath = "\\$NetworkHost\NetworkFolder"
$SessionTimeOut = 1 #minutes
$MinimumPinSize = 4
$Today = Get-Date
$CredentialsValidityPeriod = 10 #days



$CredentialsFolderPath = "$env:USERPROFILE\AppData\Local\CredentialSwitcher"
$CredentialsFilePath = "$CredentialsFolderPath\Credentials.txt"
$PrivilegedCredentialsUsername = "admin"
$UnprivilegedCredentialsUsername = "Alvaro"
$NetworkShareDriveLetter = "Q:"
$NetworkHost="NAS" # host name or IP address
$NetworkSharePath = "\\$NetworkHost\Portal"
$SessionTimeOut = 0.5 #minutes
$MinimumPinSize = 4
$Today = Get-Date
$CredentialsValidityPeriod = 10 #days




function Start-GCTimeoutDialog {
  [CmdletBinding(HelpUri = 'https://github.com/grantcarthew/GCPowerShell')]
  [OutputType([String])]
  Param (
  [Parameter(Mandatory=$false)]
  [String]
  $Title = "Timeout",

  [Parameter(Mandatory=$false)]
  [String]
  $Message = "Timeout Message",

  [Parameter(Mandatory=$false)]
  [String]
  $Button1Text = "OK",

  [Parameter(Mandatory=$false)]
  [String]
  $Button2Text = "Cancel",

  [Parameter(Mandatory=$false)]
  [Int]
  $Seconds = 30
  )
  Write-Verbose -Message "Function initiated: $($MyInvocation.MyCommand)"

  Add-Type -AssemblyName PresentationCore
  Add-Type -AssemblyName PresentationFramework

  $window = $null
  $button1 = $null
  $button2 = $null
  $label = $null
  $timerTextBox = $null
  $timer = $null
  $timeLeft = New-TimeSpan -Seconds $Seconds
  $oneSec = New-TimeSpan -Seconds 1

  # Windows Form
  $window = New-Object -TypeName System.Windows.Window
  $window.Title = $Title
  $window.SizeToContent = "Height"
  $window.MinHeight = 160
  $window.Width = 310
  $window.WindowStartupLocation = "CenterScreen"
  $window.Topmost = $true
  $window.ShowInTaskbar = $false
  $window.ResizeMode = "NoResize"

  # Form Layout
  $grid = New-Object -TypeName System.Windows.Controls.Grid
  $topRow = New-Object -TypeName System.Windows.Controls.RowDefinition
  $topRow.Height = "Auto"
  $middleRow = New-Object -TypeName System.Windows.Controls.RowDefinition
  $middleRow.Height = "*"
  $bottomRow = New-Object -TypeName System.Windows.Controls.RowDefinition
  $bottomRow.Height = "Auto"
  $grid.RowDefinitions.Add($topRow)
  $grid.RowDefinitions.Add($middleRow)
  $grid.RowDefinitions.Add($bottomRow)
  $buttonStack = New-Object -TypeName System.Windows.Controls.StackPanel
  $buttonStack.Orientation = "Horizontal"
  $buttonStack.VerticalAlignment = "Bottom"
  $buttonStack.HorizontalAlignment = "Center"
  $buttonStack.Margin = "0,5,5,5"
  [System.Windows.Controls.Grid]::SetRow($buttonStack,2)
  $grid.AddChild($buttonStack)
  $window.AddChild($grid)

  # Button One
  $button1 = New-Object -TypeName System.Windows.Controls.Button
  $button1.MinHeight = 23
  $button1.MinWidth = 75
  $button1.VerticalAlignment = "Bottom"
  $button1.HorizontalAlignment = "Right"
  $button1.Margin = "0,0,0,0"
  $button1.Content = $Button1Text
  $button1.Add_Click({$window.Tag=$Button1Text;$window.Close()})
  $button1.IsDefault = $true
  $buttonStack.AddChild($button1)

  # Button Two
  $button2 = New-Object -TypeName System.Windows.Controls.Button
  $button2.MinHeight = 23
  $button2.MinWidth = 75
  $button2.VerticalAlignment = "Bottom"
  $button2.HorizontalAlignment = "Right"
  $button2.Margin = "8,0,0,0"
  $button2.Content = $Button2Text
  $button2.Add_Click({$window.Tag=$Button2Text;$window.Close()})
  $button2.IsCancel = $true
  $buttonStack.AddChild($button2)

  # Message Label
  $label = New-Object -TypeName System.Windows.Controls.TextBox
  $label.TextWrapping = "WrapWithOverflow"
  $label.BorderThickness = 0
  $label.Margin = "5,0,0,0"
  $label.Text = $Message
  [System.Windows.Controls.Grid]::SetRow($label,0)
  $grid.AddChild($label)

  # Count Down Textbox
  $timerTextBox = New-Object -TypeName System.Windows.Controls.TextBox
  $timerTextBox.Width = "150"
  $timerTextBox.Height = "20"
  $timerTextBox.Margin = "0,10,0,10"
  $timerTextBox.TextAlignment = "Center"
  $timerTextBox.IsReadOnly = $true
  $timerTextBox.Text = $timeLeft.ToString()
  [System.Windows.Controls.Grid]::SetRow($timerTextBox,1)
  $grid.AddChild($timerTextBox)

  # Windows Timer
  $timer = New-Object -TypeName System.Windows.Threading.DispatcherTimer

  $timer.Interval = New-TimeSpan -Seconds 1
  $timer.Tag = $timeLeft
  $timer.Add_Tick({
    $timer.Tag = $timer.Tag - $oneSec
    $timerTextBox.Text = $timer.Tag.ToString()
    if ($timer.Tag.TotalSeconds -lt 1) { $window.Tag = "TIMEOUT"; $window.Close() }
  })
  $timer.IsEnabled = $true
  $timer.Start()

  # Show
  $window.Activate() | Out-Null
  $window.ShowDialog() | Out-Null
  $window.Tag
  $timer.IsEnabled = $false
  $timer.Stop()
  $window = $null
  $button1 = $null
  $button2 = $null
  $label = $null
  $timerTextBox = $null
  $timer = $null
  $timeLeft = $null
  $oneSec = $null

  Write-Verbose -Message "Function completed: $($MyInvocation.MyCommand)"
}

#---------------------------------------------------------------------------------------------------------------------------------------------
# Check for stored credentials
# If credentials were not saved (or if they have expired), ask user for privileged and unprivileged credentials, encrypt them and save them
$ValidCredentials = $false
if (Test-Path -Path $CredentialsFilePath) {if ((Get-Item $CredentialsFilePath).LastWriteTime.AddDays($CredentialsValidityPeriod) -gt $Today) { $ValidCredentials=$true}}
if (-not($ValidCredentials)) {  
    #Ask user for credentials
    $PrivilegedCredentials = $host.ui.PromptForCredential("Privileged Credentials", "Please enter password", $PrivilegedCredentialsUsername, "")
    $UnprivilegedCredentials = $host.ui.PromptForCredential("Unprivileged Credentials", "Please enter password", $UnprivilegedCredentialsUsername, "")

    #Ask use to set a Passcode
    $KeySS =  Read-Host "Please set Passcode" -asSecureString
    if (($KeySS.Length -lt $MinimumPinSize) -or ($KeySS.Length -gt 16)) {
        Write-Host "Pin must be between $MinimumPinSize to 16 characters long"
        Exit
    }
    
    #Pad key up to 16 bytes long
    for ($i=$KeySS.Length; $i -lt 16; $i++) {
        $KeySS.AppendChar([char]32)
    }    

    $EncryptedPrivileged = ConvertFrom-SecureString -SecureString $PrivilegedCredentials.Password -SecureKey $KeySS
    $EncryptedUnprivileged = ConvertFrom-SecureString -SecureString $UnprivilegedCredentials.Password -SecureKey $KeySS

    Write-Host $EncryptedPrivileged.Length
    Write-Host $EncryptedUnprivileged.Length

    New-Item -Path $CredentialsFilePath -ItemType "file" -Value "$EncryptedPrivileged`r`n" -Force
    Add-Content -Path $CredentialsFilePath -Value $EncryptedUnprivileged -Force
    
    Write-Host "Credentials saved to $CredentialsFilePath"
}
#---------------------------------------------------------------------------------------------------------------------------------------------

Add-Type -AssemblyName System.Windows.Forms

# Ask for Passcode, Decrypt and Mount
$KeySS =  Read-Host "Please enter Passcode" -asSecureString
if (($KeySS.Length -lt $MinimumPinSize) -or ($KeySS.Length -gt 16)) {
    Write-Host "Pin must be between $MinimumPinSize to 16 characters long"
    Exit
}
    
#Pad key up to 16 bytes long
for ($i=$KeySS.Length; $i -lt 16; $i++) {
    $KeySS.AppendChar([char]32)
}   


($EncryptedPrivileged, $EncryptedUnprivileged) = Get-Content -Path "$CredentialsFilePath"

$PrivilegedPasswordSS = ConvertTo-SecureString -String $EncryptedPrivileged -SecureKey $KeySS
$UnprivilegedPasswordSS = ConvertTo-SecureString -String $EncryptedUnprivileged -SecureKey $KeySS

$PrivilegedCredentials = New-Object System.Management.Automation.PsCredential($PrivilegedCredentialsUsername, $PrivilegedPasswordSS)
$UnprivilegedCredentials = New-Object System.Management.Automation.PsCredential($UnprivilegedCredentialsUsername, $UnprivilegedPasswordSS)

#Switch
net use /delete $NetworkShareDriveLetter /y
cmdkey /delete:$NetworkHost
Start-Process PowerShell -Verb RunAs -ArgumentList "Disable-NetAdapter -Name Ethernet -Confirm:$false"
do {} while ((Get-NetAdapter Ethernet).Status -ne "Disabled")
Start-Process PowerShell -Verb RunAs -ArgumentList "Enable-NetAdapter -Name Ethernet -Confirm:$false"
do {} while ((Get-NetAdapter Ethernet).Status -ne "Up")
do{
Start-Sleep -Milliseconds  1000
$Result= &{ net use $NetworkShareDriveLetter $NetworkSharePath /user:$($PrivilegedCredentials.UserName) "$($PrivilegedCredentials.GetNetworkCredential().Password)" } *>&1
} while (-not $Result.Contains('The command completed successfully.'))



do {
Start-Sleep -Milliseconds  ($SessionTimeOut * 60000)
    #$msgBoxInput = [Windows.Forms.MessageBox]::Show('Credentials are going to be switched back to unpriviledged. If you would like to continue working with admin credentials please press cancel','Credential Switching', [Windows.Forms.MessageBoxButtons]::OKCancel, [Windows.Forms.MessageBoxIcon]::Question)
    $msgBoxInput = Start-GCTimeoutDialog -Title "Credential Switcher" -Message "Credentials are going to be switched back to unpriviledged. If you would like to continue working with privileged credentials please press Cancel." -Seconds 10
} while ($msgBoxInput -eq 'Cancel')


# SwitchCredentials Back
net use /delete $NetworkShareDriveLetter /y
cmdkey /delete:$NetworkHost
Start-Process PowerShell -Verb RunAs -ArgumentList "Disable-NetAdapter -Name Ethernet -Confirm:$false"
do {} while ((Get-NetAdapter Ethernet).Status -ne "Disabled")
Start-Process PowerShell -Verb RunAs -ArgumentList "Enable-NetAdapter -Name Ethernet -Confirm:$false"
do {} while ((Get-NetAdapter Ethernet).Status -ne "Up")
cmdkey /add:$NetworkHost /user:$($UnprivilegedCredentials.UserName) /pass:"$($UnprivilegedCredentials.GetNetworkCredential().Password)"
do{
Start-Sleep -Milliseconds  1000
$Result= &{ net use $NetworkShareDriveLetter $NetworkSharePath /user:$($UnprivilegedCredentials.UserName) "$($UnprivilegedCredentials.GetNetworkCredential().Password)"} *>&1
} while (-not $Result.Contains('The command completed successfully.'))





# taskkill /f /IM explorer.exe
# Start-Sleep -Milliseconds  400
# 
# Start-Sleep -Milliseconds  600
# start explorer.exe

# Start-Process PowerShell -Verb RunAs -ArgumentList "Disable-NetAdapter -Name Ethernet -Confirm:$false"
# Start-Sleep -Milliseconds  400
# Start-Process PowerShell -Verb RunAs -ArgumentList "Enable-NetAdapter -Name Ethernet -Confirm:$false"
# Start-Sleep -Milliseconds  2000




#  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#  Update-SmbMultichannelConnection
#  netsh interface show interface
#  netsh interface set interface "YOUR-ADAPTER-NAME" disable
#  netsh interface set interface "YOUR-ADAPTER-NAME" enable
#  Start-Process PowerShell -Verb RunAs -ArgumentList "netsh interface set interface Ethernet disable"
#  Get-NetAdapter | format-table
#  Disable-NetAdapter -Name Ethernet -Confirm:$false
#  Enable-NetAdapter -Name Ethernet -Confirm:$false
#  Get-SmbClientConfiguration
#  Get-SmbSession
#  Start-Process powershell -Verb runAs



do{
    cls
    get-smbconnection
    #Get-NetAdapter Ethernet | format-table
    #Get-NetAdapter Ethernet | Format-List -Property "Status"
     (Get-NetAdapter Ethernet).Status
    Start-Sleep -Milliseconds  700
} while ($true)




# named pipe - server
$name = 'foo'
$namedPipe = New-Object IO.Pipes.NamedPipeServerStream($name, 'InOut')
$namedPipe.WaitForConnection()

$script:writer = New-Object IO.StreamWriter($namedPipe)
$writer.AutoFlush = $true
$writer.WriteLine('something')
$writer.Dispose()



$namedPipe.Dispose()

# named pipe - client
$name = 'CredentialSwitcher'
$namedPipe = New-Object IO.Pipes.NamedPipeClientStream('.', $name, 'InOut')
$namedPipe.Connect()
$script:writer = New-Object IO.StreamWriter($namedPipe)

$writer.WriteLine('RESET')
$writer.Dispose()
$script:reader = New-Object IO.StreamReader($namedPipe)

$reader.ReadLine()
$reader.Dispose()
$namedPipe.Dispose() 











$continue = $true
while($continue)
{

    if ([console]::KeyAvailable)
    {
        echo "Toggle with F12";
        $x = [System.Console]::ReadKey() 

        switch ( $x.key)
        {
            F12 { $continue = $false }
        }
    } 
    else
    {
        $wsh = New-Object -ComObject WScript.Shell
        $wsh.SendKeys('{CAPSLOCK}')
        sleep 1
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wsh)| out-null
        Remove-Variable wsh
    }    
}









Param
 (
	[String]$Restart	
 )

If ($Restart -ne "") 
	{
		sleep 10
	} 

$Current_Folder = split-path $MyInvocation.MyCommand.Path




 
 
 # When Exit is clicked, close everything and kill the PowerShell process
$Menu_Restart_Tool.add_Click({
	$Restart = "Yes"
	start-process -WindowStyle hidden powershell.exe "C:\ProgramData\MySystrayTool\PS1_Systray_Tool.ps1 '$Restart'" 	

	$Main_Tool_Icon.Visible = $false
	$window.Close()
	Stop-Process $pid	
 })
 
 




 # Network Adapter Reset
#---------------------------------------------------------------------------------------------------------------------------------------------
Function ResetNetworkAdapter {
[console]::beep(900,3000)
Disable-NetAdapter -Name Ethernet -Confirm:$false
do {} while ((Get-NetAdapter Ethernet).Status -ne "Disabled")
Enable-NetAdapter -Name Ethernet -Confirm:$false
do {} while ((Get-NetAdapter Ethernet).Status -ne "Up")
$NotifyIcon.ShowBalloonTip(30000,"Attention!","Network Adapter Reset",[system.windows.forms.ToolTipIcon]"Warning")
}



 $scriptblock = {
param($myParam); 
    # My commands here
# TCP socket - server
$addr = [ipaddress]'127.0.0.1'
$port = 1234

$endpoint = New-Object Net.IPEndPoint ($addr, $port)
$server = New-Object Net.Sockets.TcpListener $endpoint
$server.Start()
$cn = $server.AcceptTcpClient()


$stream = $cn.GetStream()
$reader = New-Object IO.StreamReader($stream)

while ($cn.Connected) {
        $command = $reader.ReadLine()
        if ($command -eq 'RESET') {[console]::beep(1900,2000);ResetNetworkAdapter; break}
        Start-Sleep -Seconds 1
        [console]::beep(900,500)
}

}

Start-Job -ScriptBlock $scriptblock -args $myParamsIWantToPassToScriptblock

While ($true){
    # To view status of that background job
    Get-Job *
    # Add your logic for fulfilling your conditons here, then
    # break; <<uncomment to break out of loop
    if ($connected)
    {
        break;
    }
    cls
    $connected
    get-smbconnection | format-table
    #Get-NetAdapter Ethernet | format-table
    #Get-NetAdapter Ethernet | Format-List -Property "Status"
     (Get-NetAdapter Ethernet).Status
    Start-Sleep -Milliseconds  700

}

# Gets the output from that job. -Keep keeps the output in memory
# if you want to call it multiple times
Receive-Job * -Keep


pause




# named pipe - client
$name = 'CredentialSwitcher'
$namedPipe = New-Object IO.Pipes.NamedPipeClientStream('.', $name, 'InOut')
$namedPipe.Connect()
$script:writer = New-Object IO.StreamWriter($namedPipe)

$writer.WriteLine('RESET')
$writer.Dispose()
$script:reader = New-Object IO.StreamReader($namedPipe)

$reader.ReadLine()
$reader.Dispose()
$namedPipe.Dispose() 










# TCP socket - server
$addr = [ipaddress]'127.0.0.1'
$port = 1234

$endpoint = New-Object Net.IPEndPoint ($addr, $port)
$server = New-Object Net.Sockets.TcpListener $endpoint
$server.Start()
$cn = $server.AcceptTcpClient()

$stream = $cn.GetStream()
$writer = New-Object IO.StreamWriter($stream)
$writer.WriteLine('something')
$writer.Dispose()

$server.Stop()




# TCP socket - client
$server = '127.0.0.1'
$port   = 1234

$client = New-Object Net.Sockets.TcpClient
$client.Connect($server, $port)
$stream = $client.GetStream()

$writer = New-Object IO.StreamWriter($stream)
$writer.WriteLine('RESET')




$reader = New-Object IO.StreamReader($stream)
$reader.ReadLine()

$reader.Dispose()

$client.Dispose()



