$null = $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(
    'Invoke-FixAutomatonFormatting', {
$psISE.CurrentFile.Editor.Text = @"
`$moduleDir = "`${Reporting_Module_Path}"
`$script = 'Module-AllAutomations.psm1'
`$ps = Join-Path -Path `$moduleDir -ChildPath `$script

`$Output = `@'
$($psISE.CurrentFile.Editor.SelectedText -replace "(Write-Output -InputObject ')|((\;)*'\|\ Out-File\ \`$ps)|( -Append)"  -replace '(?smi)(^\s+)',"    ")
'`@

Set-Content -Path `$PS -Value `$Output
"@
    }, 'CTRL+ALT+I'
)

<# Remove the script

$remove = $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Remove($psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Where{$_.DisplayName -eq 'Invoke-FixAutomatonFormatting'})
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Remove($psISE.CurrentPowerShellTab.AddOnsMenu.Submenus[1])

#>