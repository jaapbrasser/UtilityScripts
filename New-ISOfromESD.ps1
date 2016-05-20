function New-ISOfromESD {
<#
.Synopsis
Create a Windows 10 Image from a fast track ESD

.DESCRIPTION
Script originally created by Johan Arvid, I have adapted this script so it can run without any hardcoded variables and created a function out of it. The orginal can be found here: http://deploymentresearch.com/Research/Post/399/How-to-REALLY-create-a-Windows-10-ISO-no-3rd-party-tools-needed

.NOTES   
Name       : New-ISOfromESD.ps1
Author     : Johan Arwidmark
UpdatedBy  : Jaap Brasser
Version    : 1.0
DateCreated: 2016-05-03
DateUpdated: 2016-05-03

.PARAMETER ESDFile
The location of the ESD File, this function will assume the current folder if it cannot find the file. If it cannot be found there it will attempt to copy it from: C:\$WINDOWS.~BT\Sources\Install.esd

.PARAMETER PathToOscdimg
Path to the oscdimg tool found in the Windows 10 ADK, required to generate the ISO

.PARAMETER ISOMediaFolder
The path where the ISOMedia will be extracted to, defaults to the current folder /Media.

.PARAMETER CleanMedia
Switch parameter that determines if the ISOMediaFolder is cleared after the ISO file creation

.EXAMPLE   
. .\New-ISOfromESD.ps1
    
Description 
-----------     
This command dot sources the script to ensure the New-ISOfromESD function is available in your current PowerShell session

.EXAMPLE   
New-ISOfromESD -CleanMedia
    
Description 
-----------     
Will create a new ISO using the default values as specified in the parameter block. Will assume that the oscdimg.exe executable is present in the current path.
#>
    [cmdletbinding(SupportsShouldProcess)]
    param (
        [string] $ESDFile        = (Get-Item -Path .\Install.esd -ErrorAction SilentlyContinue |
                                    Select-Object -ExpandProperty FullName),
        [string] $PathToOscdimg  = (Get-Item -Path .\oscdimg.exe -ErrorAction SilentlyContinue |
                                    Select-Object -ExpandProperty FullName),
        [string] $ISOMediaFolder = (Join-Path (Get-Location) 'Media'),
        [switch] $CleanMedia
    )
    
    process {
        if ($ESDFile) {
            if (-not (Test-Path -LiteralPath $ESDFile -EA 0) -and -not (Test-Path -LiteralPath 'C:\$WINDOWS.~BT\Sources\Install.esd')) {
                Throw 'Could not find Install.esd, please ensure this file is present in the current folder'
            } elseif (-not (Test-Path .\Install.esd)) {
                Write-Verbose 'Copying Install.esd from ''C:\$WINDOWS.~BT\Sources\'''
                Copy-Item -LiteralPath 'C:\$WINDOWS.~BT\Sources\Install.esd' -Destination '.\Install.esd'
            }
        }

        try {
            Get-Item -Path .\Install.esd -ErrorAction Stop
        } catch {
            throw $_
        }

        if (-not (Test-Path -LiteralPath $ISOMediaFolder)) {
            Write-Verbose -Message 'Create ISO folder'
            New-Item -ItemType Directory $ISOMediaFolder -ErrorAction SilentlyContinue
        }

        if (Get-ChildItem -LiteralPath $ISOMediaFolder) {
            Write-Warning "Folder '$ISOMediaFolder' already contains files, this might interfere with ISO creation"
        }
        
        Write-Verbose -Message 'Create ISO folder structure using dism.exe'
        dism.exe /Apply-Image /ImageFile:$ESDFile /Index:1 /ApplyDir:$ISOMediaFolder
  
        Write-Verbose -Message 'Create empty boot.wim file with compression type set to maximum'
        New-Item -ItemType Directory 'C:\EmptyFolder' -ErrorAction SilentlyContinue
        dism.exe /Capture-Image /ImageFile:$ISOMediaFolder\sources\boot.wim /CaptureDir:C:\EmptyFolder /Name:EmptyIndex /Compress:max
  
        Write-Verbose -Message 'Export base Windows PE to empty boot.wim file (creating a second index)'
        dism.exe /Export-image /SourceImageFile:$ESDFile /SourceIndex:2 /DestinationImageFile:$ISOMediaFolder\sources\boot.wim /Compress:Recovery /Bootable
  
        Write-Verbose -Message 'Delete the first empty index in boot.wim'
        dism.exe /Delete-Image /ImageFile:$ISOMediaFolder\sources\boot.wim /Index:1
  
        Write-Verbose -Message 'Export Windows PE with Setup to boot.wim file'
        dism.exe /Export-image /SourceImageFile:$ESDFile /SourceIndex:3 /DestinationImageFile:$ISOMediaFolder\sources\boot.wim /Compress:Recovery /Bootable
  
        Write-Verbose -Message 'Display info from the created boot.wim'
        dism.exe /Get-WimInfo /WimFile:$ISOMediaFolder\sources\boot.wim
  
        Write-Verbose -Message 'Create empty install.wim file with MDT/ConfigMgr friendly compression type (maximum)'
        dism.exe /Capture-Image /ImageFile:$ISOMediaFolder\sources\install.wim /CaptureDir:C:\EmptyFolder /Name:EmptyIndex /Compress:max
  
        Write-Verbose -Message 'Export Windows Technical Preview to empty install.wim file'
        dism.exe /Export-image /SourceImageFile:$ESDFile /SourceIndex:4 /DestinationImageFile:$ISOMediaFolder\sources\install.wim /Compress:Recovery
  
        Write-Verbose -Message 'Delete the first empty index in install.wim'
        dism.exe /Delete-Image /ImageFile:$ISOMediaFolder\sources\install.wim /Index:1
  
        Write-Verbose -Message 'Display info from the created install.wim'
        dism.exe /Get-WimInfo /WimFile:$ISOMediaFolder\sources\install.wim
  
        Write-Verbose -Message 'Create the Windows Technical Preview ISO, For more info on the Oscdimg.exe commands, check this post: http://support2.microsoft.com/kb/947024'
  
        $BootData='2#p0,e,b"{0}"#pEF,e,b"{1}"' -f "$ISOMediaFolder\boot\etfsboot.com","$ISOMediaFolder\efi\Microsoft\boot\efisys.bin"
        $NewISO  = "windows_10_insider_preview_$((Get-Item -Path (Join-Path $ISOMediaFolder Setup.exe)).VersionInfo.FileVersion).iso" -replace '\s'

        $Proc = Start-Process -FilePath $PathToOscdimg -ArgumentList @("-bootdata:$BootData",'-u2','-udfver102',"$ISOMediaFolder","$NewISO") -PassThru -Wait -NoNewWindow
        if($Proc.ExitCode -ne 0) {
            Write-Error "Failed to generate ISO with exitcode: $($Proc.ExitCode)"
        }

        if ($CleanMedia) {
            Write-Verbose -Message "Cleaning up remaining files in $ISOMediaFolder"
            Remove-Item -Recurse -Path $ISOMediaFolder
        }
    }
}