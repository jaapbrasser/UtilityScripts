﻿<#
.SYNOPSIS Script to compress the WinSxs folder to free up diskspace
#>
[cmdletbinding(SupportsShouldProcess=$true)]
param()

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
        SpaceSavedGB       = [math]::Round((($InputObject[-2] -replace '^(.*?)\stotal.*$','$1' -replace '\D' -as [long]) -
                             ($InputObject[-2] -replace '.*?in\s(.*?)\sbytes.*','$1' -replace '\D' -as [long]))/1GB,2)
        CompressionRatio   = $InputObject[-1] -replace '.*?is\s(.*?)\sto.*?$','$1'                -as [decimal]
        Target             = $InputObject[1] -replace '.*?in\s(.*?)$','$1'                        -as [System.IO.DirectoryInfo]
    }
}
1 -
2
# Set startup mode to Disabled and store current startup configuration
$Service = @{}
if (Test-ServiceObject) {
    $Service.MSIServer, $Service.TrustedInstaller = Get-Service -Name msiserver,trustedinstaller |
                                                    Select-Object -ExpandProperty StartType
    Get-Service -Name msiserver,trustedinstaller | Set-Service -StartupType Disabled -ErrorAction SilentlyContinue
} else {
    $Service.MSIServer        = Get-WmiObject -Query "Select StartMode FROM win32_service Where name='msiserver'" -ErrorAction SilentlyContinue |
                                Select-Object -ExpandProperty StartMode
    $Service.TrustedInstaller = Get-WmiObject -Query "Select StartMode FROM win32_service Where name='trustedinstaller'" -ErrorAction SilentlyContinue |
                                Select-Object -ExpandProperty StartMode
}

# Stop services
Get-Service -Name msiserver,trustedinstaller | Stop-Service -Force -Verbose

# Backup WinSxS ACL
$null = & ${env:windir}\system32\icacls.exe "${env:windir}\WinSxS" /save "${env:userprofile}\Backupacl.acl"

# Take ownership and set ACL
Invoke-ParseTakeOwn -InputObject (& ${env:windir}\system32\takeown.exe /f "${env:windir}\WinSxS" /r 2>&1) |
Tee-Object -Variable TakeOwn  | Format-Table -AutoSize | Out-String | Write-Verbose

Invoke-ParseIcacls  -InputObject (& ${env:windir}\system32\icacls.exe "${env:windir}\WinSxS" /grant "${env:userdomain}\${env:username}:(F)" /t 2>&1) |
Tee-Object -Variable SetAcl   | Format-Table -AutoSize | Out-String | Write-Verbose

# Compress WinSxS
Invoke-ParseCompact -InputObject (& ${env:windir}\system32\compact.exe /s:"${env:windir}\WinSxS" /c /a /i * 2>&1) |
Tee-Object -Variable Compress | Format-Table -AutoSize | Out-String | Write-Verbose

# Restore WinSxS ACL
Invoke-ParseIcacls  -InputObject (& ${env:windir}\system32\icacls.exe "${env:windir}\WinSxS" /setowner "NT SERVICE\TrustedInstaller" /t 2>&1) |
Tee-Object -Variable SetOwn   | Format-Table -AutoSize | Out-String | Write-Verbose

Invoke-ParseIcacls  -InputObject (& ${env:windir}\system32\icacls.exe "${env:windir}" /restore "${env:userprofile}\Backupacl.acl" 2>&1) |
Tee-Object -Variable ResAcl   | Format-Table -AutoSize | Out-String | Write-Verbose

# Remove backup acl
Remove-Item "${env:userprofile}\Backupacl.acl"

# Start services and set startup to old value
if (Test-ServiceObject) {
    Set-Service -Name msiserver        -ErrorAction SilentlyContinue -StartupType $Service.MSIServer
    Set-Service -Name trustedinstaller -ErrorAction SilentlyContinue -StartupType $Service.TrustedInstaller
} else {
    (Get-WmiObject -Query "Select * FROM win32_service Where name='msiserver'").ChangeStartMode($Service.MSIServer)
    (Get-WmiObject -Query "Select * FROM win32_service Where name='trustedinstaller'").ChangeStartMode($Service.TrustedInstaller)
}

# Start services
$null = Start-Service -Name msiserver,trustedinstaller -ErrorAction SilentlyContinue -Verbose

# Merge all output and write output to console
Write-Output TakeOwn SetAcl Compress SetOwn ResAcl | ForEach-Object -Begin {
    $Hash   = @{}
    $SelectSplat = @{
        Property = @()
    }
} -Process {
    $Var = Get-Variable -Name $_
    $Var.value.psobject.properties | Select-Object -ExpandProperty Name | ForEach-Object {
        $SelectSplat.Property += "$($Var.Name)$_"
        $Hash."$($Var.Name)$_" = $Var.value.$_
    }
} -End {
    New-Object -TypeName PSCustomObject -Property $Hash | Select-Object @SelectSplat
}