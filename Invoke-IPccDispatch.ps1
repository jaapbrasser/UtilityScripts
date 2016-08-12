param (
    $Sender
)

begin {
    function Get-IPRadarURL {
        param(
            $IPPCFolder
        )
        ((Get-ChildItem -LiteralPath (Join-Path -Path $env:appdata -ChildPath ".purple\logs\jabber\jbrasser@jabber.ipsoft.com\$IPPCFolder") |
        Sort-Object LastWriteTime | Select-Object -Last 1 | Get-Content -Raw) -split '(https.*?\d{8})')[3]
    }
    function Get-IPimURL {
        param(
            $IPPCFolder
        )
        ((Get-ChildItem -LiteralPath (Join-Path -Path $env:appdata -ChildPath ".purple\logs\jabber\jbrasser@jabber.ipsoft.com\$IPPCFolder") |
        Sort-Object LastWriteTime | Select-Object -Last 1 | Get-Content -Raw) -split '(https.*?\d{8})')[1]
    }
}

process {
    $Sender | Out-File -Append -FilePath C:\Script\Log\Dispatch.log
    (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') | Out-File -Append -FilePath C:\Script\Log\LastRun.log
    Get-IPRadarURL -IPPCFolder ($Sender -replace '/.*')
}