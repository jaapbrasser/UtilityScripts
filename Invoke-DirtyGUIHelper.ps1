function Invoke-DirtyGUIHelper {
<#
.Synopsis
Send ALT+Y to the specified process

.DESCRIPTION
Uses user32.dll and Windows.Forms to active a process and send the ALT+Y key combination.

.NOTES   
Name       : Invoke-DirtyGUIHelper.ps1
Author     : Jaap Brasser
Version    : 1.0
DateCreated: 2016-05-03
DateUpdated: 2016-05-03
Blog       : http://www.jaapbrasser.com

.LINK
http://www.jaapbrasser.com

.PARAMETER ProcessName
The name of the program on which prompt ALT + Y will be send

.EXAMPLE   
. .\Invoke-DirtyGUIHelper
    
Description 
-----------     
This command dot sources the script to ensure the Invoke-DirtyGUIHelper function is available in your current PowerShell session

.EXAMPLE   
Invoke-DirtyGUIHelper -ProcessName firefox
    
Description 
-----------     
Will attempt to activate the firefox windows 5 times and afterwards sending the ALT + Y combination to the program
#>
    param(
        [Parameter(Mandatory,
                   Position=0
        )]
        $ProcessName
    )

    begin {
        Add-Type -Name Win -Namespace Native -Member ('[DllImport("user32.dll")]',
                                                     '[return: MarshalAs(UnmanagedType.Bool)]',
                                                     'public static extern bool SetForegroundWindow(IntPtr hWnd);' -join "`r`n")
        $Process = Get-Process $ProcessName
        Add-Type -AssemblyName System.Windows.Forms
    }

    process {
        $Count = 0
        while ($($Process.Refresh();$Process.ProcessName)) {
            $null     = [Native.Win]::SetForegroundWindow($CleanMgrProc.MainWindowHandle)
            Start-Sleep -Milliseconds 500
            [System.Windows.Forms.SendKeys]::Send('%Y')
            Start-Sleep -Milliseconds 500
            $Count++
            if ($Count -eq 5) {
                $Process = $null
            }
        }
    }
}