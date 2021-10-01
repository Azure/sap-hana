Function New-LogFile {
    <#
      .SYNOPSIS
         Instantiate new emty object and adds properties and methods for Log.
      .DESCRIPTION
         This function Instantiate (creates new instance of an object) and adds 
         properties and methods to support Logging. This is done to allow calling
         script to create it's own object with log file name specific to the script.
      .PARAMETER scriptName
         Name of the script/program to be used with logged messages.
      .PARAMETER logName
         Full Name of the file where messages will be written.
      .EXAMPLE
        $scriptInfo = Get-ScriptInfo
        $logFileName = $scriptInfo.Path + '\' + $scriptInfo.Name + '.log'
        Switch-LogFile -Name $logFileName
        $hlog = New-LogFile ($scriptInfo.Name, $logFileName)
    #>
    param(
        [string]
        $scriptName = $SCRIPT:ScriptName,
        [string]
        $logName = $SCRIPT:LogFileName
    )
    try{
        New-Object Object |            
            Add-Member NoteProperty LogFileName $logName -PassThru |             
            Add-Member NoteProperty ScriptBaseName $scriptName -PassThru |             
            Add-Member ScriptMethod SetLogFileName {            
                param([string] $logFileName)            
                    $this.LogFileName = $logFile            
                } -PassThru |
            Add-Member ScriptMethod GetLogFileName {            
                param([string] $logFileName)            
                    $this.LogFileName            
                } -PassThru |
            Add-Member ScriptMethod WritePSInfo {            
            <#
                .SYNOPSIS
                Write entry to log file.
            #>
                param($message)            
                    Write-Log $this.ScriptBaseName $this.LogFileName $MSGTYPE_INFORMATION $message
                } -PassThru |
            Add-Member ScriptMethod WritePSWarning {            
            <#
                .SYNOPSIS
                Write warning entry to log file
            #>
                param($message)            
                    Write-Log $this.ScriptBaseName $this.LogFileName $MSGTYPE_WARNING $message
                } -PassThru |
            Add-Member ScriptMethod WritePSError {            
            <#
                .SYNOPSIS
                Write error entry to log file.
            #>
                param($message)            
                    Write-Log $this.ScriptBaseName $this.LogFileName $MSGTYPE_ERROR $message
                } -PassThru
    } catch{
        $ex = $_.Exception
        $excMsg = $ex.Message.ToString()
        Write-Host "[New-LogFile]: $($excMsg)" -Fore Red
        while ($ex.InnerException)
        {
            $ex = $ex.InnerException
            $excMsg = $ex.InnerException.Message.ToString()
            Write-Host "[New-LogFile]: $($excMsg)" -Fore Red
        }
    }
}
# End Function New-LogFile 