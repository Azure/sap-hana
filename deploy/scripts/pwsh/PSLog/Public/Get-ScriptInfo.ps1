Function Get-ScriptInfo(){
<#
    .SYNOPSIS
        Get script information and return script base name and path.
    .DESCRIPTION
    Get a script name and returns script base name and path.
    The function does not take any parameters.
    .EXAMPLE
        $scriptInfo = Get-ScriptInfo; $scriptInfo.Name; $scriptInfo.Path
        
        Parent
        C:\powershell\utilities
#>
    try
    {
    $scriptPath = $MyInvocation.ScriptName.ToString()
    Write-Debug "script path: $scriptPath"
    $scriptName = [System.IO.Path]::GetFilenameWithoutExtension($scriptPath)
    $scriptDir = [System.IO.Path]::GetDirectoryName($scriptPath)
    #Get the proper path to the log file.
    if($scriptDir -eq ""){ #The script is in root of the drive.
        $currPath = Resolve-Path "."
        $scriptDir = $currPath.Path.ToString()
    }
    return (@{Name = $scriptName; Path = $scriptDir})
    }
    catch
    {
        $ex = $_.Exception
        $excMsg = $ex.Message.ToString()
        Write-Host "[Get-ScriptInfo]: $($excMsg)" -Fore Red
        while ($ex.InnerException)
        {
            $ex = $ex.InnerException
            $excMsg = $ex.InnerException.Message.ToString()
            Write-Host "[Get-ScriptInfo]: $($excMsg)" -Fore Red
        }
    }
    finally
    {
        #Caller should instantiate Logger object and set file properties based on script name.
        #In order to avoid that we can set these by default for the calling script.
        $SCRIPT:ScriptName = $scriptName
        $SCRIPT:LogFileName = $scriptDir + '\' + $scriptName + '.log'
    }
}
# End Function Get-ScriptInfo