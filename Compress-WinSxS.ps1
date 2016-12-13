function Test-ServiceObject {
    $ServiceObject = New-Object -TypeName System.ServiceProcess.ServiceController
    if (Get-Member -InputObject $ServiceObject -MemberType Property -Name StartType) {
        $true
    } else {
        $false
    }
}

# Set startup mode to Disabled and store current startup configuration
$Service = @{}
if (Test-ServiceObject) {
    $Service.MSIServer, $Service.TrustedInstaller = Get-Service -Name msiserver,trustedinstaller |
                                                    Select-Object -ExpandProperty StartType
    Get-Service -Name msiserver,trustedinstaller | Set-Service -StartupType Disabled -Verbose
} else {
    $Service.MSIServer        = Get-WmiObject -Query "Select StartMode FROM win32_service Where name='msiserver'" |
                                Select-Object -ExpandProperty StartMode
    $Service.TrustedInstaller = Get-WmiObject -Query "Select StartMode FROM win32_service Where name='trustedinstaller'" |
                                Select-Object -ExpandProperty StartMode
}

# Stop services
Get-Service -Name msiserver,trustedinstaller | Stop-Service -Force -Verbose

# Backup WinSxS ACL
& ${env:windir}\system32\icacls.exe "${env:windir}\WinSxS" /save "${env:userprofile}\Backupacl.acl"

# Take ownership and set ACL
& ${env:windir}\system32\takeown.exe /f "${env:windir}\WinSxS" /r
& ${env:windir}\system32\icacls.exe "${env:windir}\WinSxS" /grant "${env:userdomain}\${env:username}:(F)" /t

# Compress WinSxS
& ${env:windir}\system32\compact.exe /s:"${env:windir}\WinSxS" /c /a /i *

# Restore WinSxS ACL
& ${env:windir}\system32\icacls.exe "${env:windir}\WinSxS" /setowner "NT SERVICE\TrustedInstaller" /t
& ${env:windir}\system32\icacls.exe "${env:windir}\WinSxS" /restore "${env:userprofile}\Backupacl.acl"

# Remove backup acl
Remove-Item "${env:userprofile}\Backupacl.acl"

# Start services and set startup to old value
if (Test-ServiceObject) {
    Set-Service -Name msiserver -StartupType $Service.MSIServer
    Set-Service -Name trustedinstaller -StartupType $Service.TrustedInstaller
} else {
    (Get-WmiObject -Query "Select * FROM win32_service Where name='msiserver'").ChangeStartMode($Service.MSIServer)
    (Get-WmiObject -Query "Select * FROM win32_service Where name='trustedinstaller'").ChangeStartMode($Service.TrustedInstaller)
}

# Start services
Start-Service -Name msiserver,trustedinstaller