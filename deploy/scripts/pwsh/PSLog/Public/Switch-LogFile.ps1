Function Switch-LogFile {
<#
    .SYNOPSIS
        Archive the log files for the script.
    .DESCRIPTION
The number of archive files we maintain is determined by the numArch parameter.
    Log file name is ProgramName.log.
    .EXAMPLE
Switch-LogFile -Name "C:\Test-PS-1\First.log" -Arch 10
#>
    Param (
        [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$false)][int]$Arch
    )
    try
    {
        $pathToFile = [System.IO.Path]::GetDirectoryName($Name)
        if ( ! (Test-Path -Path "$pathToFile")) {
        $pathToFile = New-Item -Path "$pathToFile" -type directory
                }
        $pathToFile = Resolve-Path $pathToFile #Get full path for paths passed like '.\filename'
        $pathToFile = Add-BackSlashToPath $pathToFile.Path.ToString()
        $isValidPath = Test-Path -Path "$pathToFile" -IsValid
        Write-Debug $isValidPath
        if(!$Arch){
            $Arch = $NumOfArchives
        }
        if($isValidPath){

            #Get path that can be used by Get-ChildItem (gci) and Test-Path
            $gciLogPath = $pathToFile + "*"
            $Name = $Name.Substring($Name.LastIndexOf('\') + 1)
            $logName = $Name.Substring(0,$Name.Length - 4)
            Write-Debug $gciLogPath
            #Test if the logfile exists
            $defaultLogExists = Test-Path -Path $gciLogPath -include $Name

            #If the default log i.e. "ScriptName.Log" exists
            if($defaultLogExists){
                $dirContent = Get-ChildItem $gciLogPath -Filter "$logName*.log" | `
                                Sort-Object -Property Name -Descending | `
                                Select-Object Name
                ForEach($fileName in $dirContent){
                    if($fileName.Name -match "^*`.\d{3}")
                    {
                        $matchVal = $Matches[0]
                        if(([int]$matchVal.SubString(1,$matchVal.Length-1)) -eq ($Arch))
                        {
                            Write-Debug "Deleting log file: $($fileName.Name)"
                            $fileToDel = $pathToFile + "$($fileName.Name)"
                            Remove-Item -LiteralPath $fileToDel
                        }else{
                            $logNum = $matchVal.SubString(1,$matchVal.Length-1)
                            $logNum = "{0:D3}" -f (([int] $logNum) + 1)
                            $newName = "$logName.$logNum.log"
                            $fullPath = $pathToFile + "$($fileName.Name)"
                            Rename-Item -Path $fullPath -NewName "$newName"
                        }
                    }
                }
                #we are done with all the preprocessing so we can now rename "Log.log"
                #as Log.001.log and create a new default log file.
                $fullPath = $pathToFile + $Name
                Write-Debug $fullPath
                Rename-Item -Path $fullPath -NewName "$logName.001.log"
                $newLogFile = New-Item -Path "$fullPath" -ItemType File -Force

            } else { #default log does not exist go ahead and create the log file.
                $fullPath = $pathToFile + $Name
                $newLogFile = New-Item -Path $fullPath -ItemType File -Force
            }
        }
    } catch{
        $ex = $_.Exception
        $excMsg = $ex.Message.ToString()
        Write-Host "[Switch-LogFile]: $($excMsg)" -Fore Red
        while ($ex.InnerException)
        {
            $ex = $ex.InnerException
            $excMsg = $ex.InnerException.Message.ToString()
            Write-Host "[Switch-LogFile]: $($excMsg)" -Fore Red
        }
    }
}
# End Function Switch-LogFile
