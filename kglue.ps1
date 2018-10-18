Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '412,238'
$Form.text                       = "K-GLUE"
$Form.TopMost                    = $false
$Form.FormBorderStyle            = 'Fixed3D'
$Form.MaximizeBox                = $false

$KES10r                          = New-Object system.Windows.Forms.RadioButton
$KES10r.ForeColor                = "red"
$KES10r.text                     = "-Remove KES10"
$KES10r.AutoSize                 = $true
$KES10r.width                    = 104
$KES10r.height                   = 20
$KES10r.location                 = New-Object System.Drawing.Point(12,60)
$KES10r.Font                     = 'Microsoft Sans Serif,10'

$KES11r                          = New-Object system.Windows.Forms.RadioButton
$KES11r.ForeColor                = "red"
$KES11r.text                     = "-Remove KES11"
$KES11r.AutoSize                 = $true
$KES11r.width                    = 104
$KES11r.height                   = 20
$KES11r.location                 = New-Object System.Drawing.Point(12,80)
$KES11r.Font                     = 'Microsoft Sans Serif,10'

$updater                          = New-Object system.Windows.Forms.RadioButton
$updater.ForeColor                = "green"
$updater.text                     = "+Updater"
$updater.AutoSize                 = $true
$updater.width                    = 104
$updater.height                   = 20
$updater.location                 = New-Object System.Drawing.Point(12,140)
$updater.Font                     = 'Microsoft Sans Serif,10'

$sysinfo                         = New-Object system.Windows.Forms.RadioButton
$sysinfo.ForeColor                = "green"
$sysinfo.text                     = "+GetSysInfo"
$sysinfo.AutoSize                 = $true
$sysinfo.width                    = 104
$sysinfo.height                   = 20
$sysinfo.location                 = New-Object System.Drawing.Point(12,160)
$sysinfo.Font                     = 'Microsoft Sans Serif,10'

$klnagchkr                       = New-Object system.Windows.Forms.RadioButton
$klnagchkr.ForeColor             = "green"
$klnagchkr.text                  = "+KLNAGchk"
$klnagchkr.AutoSize              = $true
$klnagchkr.width                 = 104
$klnagchkr.height                = 20
$klnagchkr.location              = New-Object System.Drawing.Point(12,120)
$klnagchkr.Font                  = 'Microsoft Sans Serif,10'

$KESforWSr                       = New-Object system.Windows.Forms.RadioButton
$KESforWSr.ForeColor                = "red"
$KESforWSr.text                  = "Remove KES10 for Windows Server"
$KESforWSr.AutoSize              = $true
$KESforWSr.width                 = 104
$KESforWSr.height                = 20
$KESforWSr.location              = New-Object System.Drawing.Point(12,100)
$KESforWSr.Font                  = 'Microsoft Sans Serif,10'

$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline              = $false
$TextBox1.width                  = 284
$TextBox1.height                 = 20
$TextBox1.location               = New-Object System.Drawing.Point(12,30)
$TextBox1.Font                   = 'Microsoft Sans Serif,10'

$GoButton                        = New-Object system.Windows.Forms.Button
$GoButton.text                   = "Go!"
$GoButton.width                  = 60
$GoButton.height                 = 30
$GoButton.location               = New-Object System.Drawing.Point(12,180)
$GoButton.Font                   = 'Microsoft Sans Serif,10'

$ProgressBar1                    = New-Object system.Windows.Forms.ProgressBar
$ProgressBar1.width              = 200
$ProgressBar1.height             = 60
$ProgressBar1.location           = New-Object System.Drawing.Point(201,167)
$progressBar1.Value              = 0

$Form.controls.AddRange(@($KES10r,$KES11r,$KESforWSr,$TextBox1,$GoButton,$klnagchkr,$updater,$sysinfo,$ProgressBar1))

$GoButton.Add_Click({go})
Function copytruck($Source, $Destination)
{
    $ErrorActionPreference= 'silentlycontinue'
    $folders = Get-ChildItem -Name -Path $source -Directory -Recurse
    $job = Start-BitsTransfer -Source $Source\*.* -Destination $Destination -asynchronous -Priority low
    while( ($job.JobState.ToString() -eq 'Transferring') -or ($job.JobState.ToString() -eq 'Connecting') )
    {
        Start-Sleep 3
    }
    Complete-BitsTransfer -BitsJob $job
    foreach ($i in $folders)
    {   
        $exists = Test-Path $Destination\$i
        if ($exists -eq $false) 
        {
            New-Item $Destination\$i -ItemType Directory
        }
        $job = Start-BitsTransfer -Source $Source\$i\*.* -Destination $Destination\$i -Description "Please wait..." -DisplayName $i
        while( ($job.JobState.ToString() -eq 'Transferring') -or ($job.JobState.ToString() -eq 'Connecting') )
        {
            Start-Sleep 3
        }
        Complete-BitsTransfer -BitsJob $job
    }
}
Function logtruck($message)
{
    $now = Get-Date
    Write-Host $now -ForegroundColor Red
    Write-Host $message -ForegroundColor Green
}
Function go
{
    $progressBar1.Value = 0
    $machine = $TextBox1.text
    $tempdir = "\\$machine\c$\KESremover"
    if (Test-Connection -ComputerName $machine -Count 1 -Quiet)
    {
        if (-not (Test-Path $tempdir))
        {
            New-Item -ItemType "directory" $tempdir
            logtruck("Temporary directory has been created on $machine")
        }
        if ($updater.checked)
        {
            $ProgressBar1.Value = $ProgressBar1.Value + 33
            if (-not (Test-Path "$tempdir\updateutility\UpdateUtility-Gui.exe"))
            {
                logtruck("Setup files missing, copying them over to ...$tempdir")
                logtruck("Please wait while the transfer job finishes...")
                copytruck "$PSScriptRoot\updateutility\" "\\$machine\c$\KESremover"
            }
            else
            {
                $ProgressBar1.Value = $ProgressBar1.Value + 33
                logtruck("Done copying files to ...$machine")
                logtruck("Starting updater on ...$machine")
                psexec.exe \\$machine cmd /c "C:\KESremover\updateutility\UpdateUtility-Console.exe -u" > updaterout.txt
                $updateresults = Get-Content .\updaterout.txt -Raw; Write-Host $updateresults
                $ProgressBar1.Value = $ProgressBar1.Value + 34
                logtruck("Update completed on $machine")
            }
        }
        if ($KES10r.Checked)
        {
            $ProgressBar1.Value = $ProgressBar1.Value + 10
            if (-not (Test-Path "$tempdir\KES10\setup.exe"))
            {
                logtruck("Setup files missing, copying them over to ...$tempdir")
                copytruck "$PSScriptRoot\KES10\" "\\$machine\c$\KESremover"
            }
            else
            {
                $ProgressBar1.Value = $ProgressBar1.Value + 10
                logtruck("Done copying files to ...$machine")        
                $ProgressBar1.Value = $ProgressBar1.Value + 15
                logtruck("Starting uninstallation routine on ...$machine")
                Start-Process psexec.exe "\\$machine cmd /k C:\KESremover\KES10\setup.exe /s /x" -Wait
            $ProgressBar1.Value = $ProgressBar1.Value + 75
            logtruck("KES10 removal has beeen completed.")
            }
        }
        if ($KES11r.Checked)
        {
            Copy-Item -Container -Recurse "$PSScriptRoot\KES11\" $tempdir
        }
        if ($KESforWSr.Checked)
        {
            Copy-Item -Container -Recurse "$PSScriptRoot\KES10WinServer\" $tempdir
        }
        if ($klnagchkr.Checked)
        {
            $ProgressBar1.Value = $ProgressBar1.Value + 50
            logtruck("Attempting to run klnagchk on $machine...")
            psexec \\$machine cmd /c "C:\Program Files (x86)\Kaspersky Lab\NetworkAgent\klnagchk.exe" > psexecout.txt
            $klnresults = Get-Content .\psexecout.txt -Raw; Write-Host $klnresults
            $ProgressBar1.Value = $ProgressBar1.Value + 50
            logtruck("KLNAGchk is complete!")
        }
        if ($sysinfo.Checked)
        {
            $ProgressBar1.Value = $ProgressBar1.Value + 10
            if (-not (Test-Path "$tempdir\getsysteminfo\GetSystemInfo.exe"))
            {
                logtruck("Setup files missing, copying them over to ...$tempdir")
                copytruck "$PSScriptRoot\getsysteminfo\" "\\$machine\c$\KESremover"
            }
            else
            {
                logtruck("Done copying files to ...$machine")
                logtruck("Starting GetSystemInfo...")
                Write-Host "BE PATIENT THIS CAN TAKE UP TO THIRTY MINUTES"  -ForegroundColor Yellow
                $ProgressBar1.Value = $ProgressBar1.Value + 15
                Start-Process psexec.exe "\\$machine cmd /k C:\KESremover\getsysteminfo\GetSystemInfo.exe /silent /output C:\report.zip" -Wait
                logtruck("Opening explorer.exe....")
                $ProgressBar1.Value = $ProgressBar1.Value + 75
                Invoke-Expression '& start explorer.exe "\\$machine\c$"'
                logtruck("Completed GetSysInfo.")
            }
        }
    }
    else
    {
        logtruck("$machine does not appear to be alive. That might be the issue.")
    }
}
Clear-Host
Write-Host '
                                    K GLUE
                                  ---------
                                version 0.?.1
                                -------------'
logtruck ("Welcome to K-GLUE!")
[void]$Form.ShowDialog()
