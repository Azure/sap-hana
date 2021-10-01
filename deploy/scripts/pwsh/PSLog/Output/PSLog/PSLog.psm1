#Set severity constants
Set-Variable -Name MSGTYPE_INFORMATION -Value 0 -Option ReadOnly
Set-Variable -Name MSGTYPE_WARNING -Value 1 -Option ReadOnly
Set-Variable -Name MSGTYPE_ERROR -Value 2 -Option ReadOnly

# Set severity description
Set-Variable -Name SEVERITY_DESC -Value 'PS-Info', 'PS-Warn', 'PS-Error' -Option Constant

# Initialize configurable settings for logging
# These values will be be used as default unless overwritten by calling script.
[int]$LogLevel = $MSGTYPE_INFORMATION

# By Default use module name and location for LogFile Name and Script Name.
# Caller should instantiate Logger object and set file properties based on script name.
$SCRIPT:LogFileName = [System.IO.Path]::GetFilenameWithoutExtension($MyInvocation.MyCommand.Path.ToString())
$SCRIPT:ScriptName = [System.IO.Path]::GetFilenameWithoutExtension($MyInvocation.MyCommand.Path.ToString())
$SCRIPT:LogFileName += '.log'

[int]$SCRIPT:NumOfArchives = 10
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
Function Add-BackSlashToPath ($Path){
<#
    .SYNOPSIS
    Add a backslash to any given path if it is missing.
    .DESCRIPTION
Powershell usually returns path without a backslash.
    This function takes care of that.
    We need not expose this to the environment.
    .EXAMPLE
Add-BackSlashToPath -Path "C:\Test-PS-1"
    C:\Test-PS-1\
    .EXAMPLE
    Add-BackSlashToPath -Path C:\Windows\System32\
    C:\Windows\System32\
    .EXAMPLE
    Add-BackSlashToPath -Path \\comp1\C$\Windows\System32
    \\comp1\C$\Windows\System32\
#>
    
    try
    {
        if(Test-Path -Path $Path -IsValid){
            if($Path -match "\\$"){
                $strPath = $Path
            }else{
                $strPath = $Path + "\"
            }
        } else{
            $strPath = ".\"
    }
    $strPath
    }
    catch
    {
        $ex = $_.Exception
        $excMsg = $ex.Message.ToString()
        Write-Host "[Add-BackSlashToPath]: $($excMsg)" -Fore Red
        while ($ex.InnerException)
        {
            $ex = $ex.InnerException
            $excMsg = $ex.InnerException.Message.ToString()
            Write-Host "[Add-BackSlashToPath]: $($excMsg)" -Fore Red
        }
    }
    
}
Function Write-Log {
<#
    .SYNOPSIS
        Write a message to the Log file.
    .DESCRIPTION
    Logs a message to the logfile if the severity is higher than or equal to $LogLevel.
    Default severity level is information.
    .PARAMETER scriptName
        Name of the script/program to be used with logged messages.
        Use the $MSGTYPE_XXXX constants.
    .PARAMETER logName
        Full Name of the file where messages will be written.
    .PARAMETER severity
        The severity of the message.  Can be Information, Warning, or Error.
        Use the $MSGTYPE_XXXX constants.
    .PARAMETER message
        A string to be printed to the log.

    .EXAMPLE
        Write-Log $MSGTYPE_ERROR "Something has gone terribly wrong!"
#>
        param(
        [string]
        $scriptName = $SCRIPT:ScriptName,
        [string]
        $logName = $SCRIPT:LogFileName,
        [Parameter(Mandatory=$true)]
        [int]
        [ValidateScript({$MSGTYPE_INFORMATION, $MSGTYPE_WARNING, $MSGTYPE_ERROR -contains $_})]
        $severity,
        [Parameter(Mandatory=$true)]
        [string]
        $message
    )
    try
    {
        if ($severity -ge $LogLevel)
        {
            $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            $callerName = (Get-PSCallStack)[2].InvocationInfo.MyCommand.Name
            $output = "$timestamp`t`[$($SEVERITY_DESC[$severity])`]: ($callerName)`t$message"

            Write-Output $output >> $logName

            switch($severity)
            {
                $MSGTYPE_INFORMATION {Write-Host $output -Fore Magenta; break}
                $MSGTYPE_WARNING 	{Write-Host $output -Fore Yellow; break}
                $MSGTYPE_ERROR 	    {Write-Host $output -Fore Red; break}
            }
        }
    }
    catch
    {
        $ex = $_.Exception
        $excMsg = $ex.Message.ToString()
        Write-Host "[Write-Log]: $($excMsg)" -Fore Red
        while ($ex.InnerException)
        {
            $ex = $ex.InnerException
            $excMsg = $ex.InnerException.Message.ToString()
            Write-Host "[Write-Log]: $($excMsg)" -Fore Red
        }
    }
}
