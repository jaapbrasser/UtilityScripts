function Get-SkypeBusinessCertificate {
    [System.IO.File]::WriteAllBytes("$env:USERPROFILE\desktop\EventCert.cer",
        (
            (
                [xml](Get-WinEvent -FilterHashtable @{
                    'Logname' = 'System'
                    'Id'      = 36882
                } -MaxEvents 1).ToXml()
            ).Event.Eventdata.Binary -split '(..)' |
            Where-Object {$_} | ForEach-Object {
                [system.convert]::ToByte($_,16)
            }
        )
    )
}