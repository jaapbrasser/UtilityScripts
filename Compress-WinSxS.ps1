$Service = @{}
$Service.MSIServer, $Service.TrustedInstaller = Get-Service -Name msiserver,trustedinstaller

# Stop services, set start up to Disabled
Get-Service -Name msiserver,trustedinstaller | Stop-Service -Force -Verbose
Get-Service -Name msiserver,trustedinstaller | Set-Service -StartupType Disabled -Verbose

# Backup WinSxS ACL
C:\WINDOWS\system32\icacls.exe "$env:windir\WinSxS" /save "$env:USERPROFILE\Backupacl.acl"

C:\WINDOWS\system32\takeown.exe /f "$env:windir\WinSxS" /r
C:\WINDOWS\system32\icacls.exe "$env:windir\WinSxS" /grant "$env:USERDOMAIN\$env:USERNAME":(F) /t
C:\WINDOWS\system32\compact.exe /s:"$env:windir\WinSxS" /c /a /i *
C:\WINDOWS\system32\icacls.exe "$env:windir\WinSxS" /setowner "NT SERVICE\TrustedInstaller" /t

# Restore WinSxS ACL
C:\WINDOWS\system32\icacls.exe "$env:windir\WinSxS" /restore "$env:USERPROFILE\Backupacl.acl"
# Remove-Item "$env:USERPROFILE\Backupacl.acl"

# Start services and set startup to old value
Set-Service -Name msiserver -StartupType $Service.MSIServer.StartType
Set-Service -Name trustedinstaller -StartupType $Service.TrustedInstaller.StartType
Start-Service -Name msiserver,trustedinstaller