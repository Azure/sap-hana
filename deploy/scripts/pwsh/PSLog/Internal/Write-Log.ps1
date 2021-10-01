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