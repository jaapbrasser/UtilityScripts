function Get-LastLogonUser {
    Get-Item 'HKLM:\Software\Microsoft\windows\currentVersion\Authentication\LogonUI\'
}