function ConvertTo-CompressedBase64 {
    [cmdletbinding()]
    param(
        [Parameter(
            ValueFromPipeline=$true
        )]
        [string] $InputObject
    )
    $ms = New-Object System.IO.MemoryStream
    $cs = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Compress)
    $sw = New-Object System.IO.StreamWriter($cs)
    $sw.Write($InputObject.ToCharArray())
    $sw.Close()
    [System.Convert]::ToBase64String($ms.ToArray())
}
$null = $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(
    'ConvertTo-CompressedString', {
        $StringBuilder = '$bd=[Convert]::FromBase64String(''{0}'')',
                         '$ms=New-Object IO.MemoryStream;$ms.Write($bd,0,$bd.Length);$null=$ms.Seek(0,0)',
                         '(New-Object IO.StreamReader((New-Object IO.Compression.GZipStream($ms,[IO.Compression.CompressionMode]0)))).ReadToEnd()|Invoke-Expression' -join ';'
        $StringBuilder -f (ConvertTo-CompressedBase64 -InputObject $psISE.CurrentFile.Editor.SelectedText) | Set-Clipboard
    }, 'CTRL+ALT+U'
)