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