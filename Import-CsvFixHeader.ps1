function Import-CsvFixHeader {
<#
.SYNOPSIS   
Function to replace square brackets in headers of a csv file
    
.DESCRIPTION 
This function was inspired by a blog post of Richard Siddaway:
https://richardspowershellblog.wordpress.com/2016/02/29/csv-file-with-in-headers/

I decided to wrap this into a short function to simplify the replacing the header names.
#>
    [cmdletbinding()]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [string] $Path
    )
    # Read the header
    $Header = Get-Content -LiteralPath $Path -Totalcount 1
    
    # Configure the regex, the current regex only replaces [square brackets]
    $Regex = [regex]'\[|]'

    # Check if brackets are found in the header
    if ($Header -match $Regex) {
        $Header -replace '"' -split ',' | ForEach-Object -Begin {
            $HashSplat = @{
                Header = @()
            }
        } -Process {
            $Count = 1
            $While = $true
            $CurrentHeader = $_ -replace $Regex
            # The do-while loop is to ensure that the header names are still unique
            do {
                if ($HashSplat.Header -notcontains $CurrentHeader) {
                    $HashSplat.Header += $CurrentHeader
                    $While = $false
                }
                if ($Count -gt 1) {
                    $CurrentHeader = $CurrentHeader -replace "$Count`$"
                }
                $CurrentHeader = "$CurrentHeader$Count"
                $Count++
            } while ($while)
        } -End {
            Import-Csv -LiteralPath $Path @HashSplat
        }
    }
}