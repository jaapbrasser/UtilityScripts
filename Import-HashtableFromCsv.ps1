function Import-HashtableFromCsv {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias("FullName")] 
        [string[]]$Path,
        [Parameter(Mandatory=$false)]
        [char]$Delimiter
    )

    process {
        # Create splat based on parameters, can be amended to allow future parameters header/encoding
        $ImportCsvSplat = @{
            Path = $Path
        }
        switch (1) {
            {$Delimiter} {$ImportCsvSplat.Delimiter = $Delimiter}
        }

        # Read csv and build hashtable
        Import-Csv @ImportCsvSplat | ForEach-Object {
            $_.psobject.Properties | Where-Object {$_.Value} | ForEach-Object -Begin {
                $SplatParams = @{}
            } -Process {
                $SplatParams[$_.Name] = $_.Value
            } -End {
                return $SplatParams
            }
        }
    }
}
