function Test-ServiceObject {
    try {
        $ServiceObject = New-Object -TypeName System.ServiceProcess.ServiceController
    } catch {
        $null          = Get-Service -Name msiserver -ErrorAction SilentlyContinue
        $ServiceObject = New-Object -TypeName System.ServiceProcess.ServiceController
    }
    if (Get-Member -InputObject $ServiceObject -MemberType Property -Name StartType) {
        $true
    } else {
        $false
    }
}

function Invoke-ParseTakeOwn {
    param(
        [string[]] $InputObject
    )
    New-Object -TypeName PSCustomObject -Property @{
        TakeOwnResultSuccess = ($InputObject -match 'Success').Count
    }
}

function Invoke-ParseIcacls {
    param(
        [string[]] $InputObject
    )
    New-Object -TypeName PSCustomObject -Property @{
        ACLResultSuccess = $InputObject[-1] -replace '.*?\s(\d*)\sfiles.*?$','$1' -as [long]
        ACLResultFailed  = $InputObject[-1] -replace '.*?\s(\d*)\sfiles$','$1'    -as [long]
        Target           = $InputObject[0]  -replace '.*?\:\s(.*?)$','$1'         -as [System.IO.DirectoryInfo]
    }
}

function Invoke-ParseCompact {
    param(
        [string[]] $InputObject
    )
    New-Object -TypeName PSCustomObject -Property @{
        Files              = $InputObject[-3] -replace '^(.*?)\s.*?\s(\d*?)\s.*?$','$1'           -as [long]
        Folders            = $InputObject[-3] -replace '^(.*?)\s.*?\s(\d*?)\s.*?$','$2'           -as [long]
        BytesPreCompressed = $InputObject[-2] -replace '^(.*?)\stotal.*$','$1' -replace '\D'      -as [long]
        BytesCompressed    = $InputObject[-2] -replace '.*?in\s(.*?)\sbytes.*','$1' -replace '\D' -as [long]
        CompressionRatio   = $InputObject[-1] -replace '.*?is\s(.*?)\sto.*?$','$1'                -as [decimal]
        Target             = $InputObject[1] -replace '.*?in\s(.*?)$','$1'                        -as [System.IO.DirectoryInfo]
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
Invoke-ParseTakeOwn -InputObject (& ${env:windir}\system32\takeown.exe /f "${env:windir}\WinSxS" /r 2>&1)
Invoke-ParseIcacls  -InputObject (& ${env:windir}\system32\icacls.exe "${env:windir}\WinSxS" /grant "${env:userdomain}\${env:username}:(F)" /t 2>&1)

# Compress WinSxS
Invoke-ParseCompact -InputObject (& ${env:windir}\system32\compact.exe /s:"${env:windir}\WinSxS" /c /a /i * 2>&1)

# Restore WinSxS ACL
Invoke-ParseIcacls  -InputObject (& ${env:windir}\system32\icacls.exe "${env:windir}\WinSxS" /setowner "NT SERVICE\TrustedInstaller" /t 2>&1)
Invoke-ParseIcacls  -InputObject (& ${env:windir}\system32\icacls.exe "${env:windir}" /restore "${env:userprofile}\Backupacl.acl" 2>&1)

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