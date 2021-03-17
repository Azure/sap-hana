function Get-IniContent {
    <#
    .SYNOPSIS
        Get-IniContent

    
.LINK
    https://devblogs.microsoft.com/scripting/use-powershell-to-work-with-any-ini-file/

    #>
    <#
#>
    [cmdletbinding()]
    param(
        #Parameter file
        [Parameter(Mandatory = $true)][string]$Path
    )
    $ini = @{}
    switch -regex -file $Path {
        "^\[(.+)\]" {
            # Section
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
        }
        "^\s(0,)(;.*)$" {
            # Comment
            $value = $matches[1]
            $CommentCount = $CommentCount + 1
            $name = "Comment" + $CommentCount
            $ini[$section][$name] = $value
        }
        "(.+?)\s*=(.*)" {
            # Key
            $name, $value = $matches[1..2]
            $ini[$section][$name] = $value
        }
    }
    return $ini
}

function Out-IniFile {
    <#
        .SYNOPSIS
            Out-IniContent
    
        
    .LINK
        https://devblogs.microsoft.com/scripting/use-powershell-to-work-with-any-ini-file/
    
        #>
    <#
    #>
    [cmdletbinding()]
    param(
        # Object
        [Parameter(Mandatory = $true)]$InputObject,
        #Ini file
        [Parameter(Mandatory = $true)][string]$Path
    )

    New-Item -ItemType file -Path $Path -Force
    $outFile = $Path

    foreach ($i in $InputObject.keys) {
        if (!($($InputObject[$i].GetType().Name) -eq "Hashtable")) {
            #No Sections
            Add-Content -Path $outFile -Value "$i=$($InputObject[$i])"
        }
        else {
            #Sections
            Add-Content -Path $outFile -Value "[$i]"
            Foreach ($j in ($InputObject[$i].keys | Sort-Object)) {
                if ($j -match "^Comment[\d]+") {
                    Add-Content -Path $outFile -Value "$($InputObject[$i][$j])"
                }
                else {
                    Add-Content -Path $outFile -Value "$j=$($InputObject[$i][$j])"
                }

            }
            Add-Content -Path $outFile -Value ""
        }
    }
}

