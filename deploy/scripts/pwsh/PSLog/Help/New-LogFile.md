---
external help file: PSLog-help.xml
Module Name: PSLog
online version:
schema: 2.0.0
---

# New-LogFile

## SYNOPSIS
Instantiate new emty object and adds properties and methods for Log.

## SYNTAX

```
New-LogFile [[-scriptName] <String>] [[-logName] <String>]
```

## DESCRIPTION
This function Instantiate (creates new instance of an object) and adds 
properties and methods to support Logging.
This is done to allow calling
script to create it's own object with log file name specific to the script.

## EXAMPLES

### EXAMPLE 1
```
$scriptInfo = Get-ScriptInfo
```

$logFileName = $scriptInfo.Path + '\' + $scriptInfo.Name + '.log'
Switch-LogFile -Name $logFileName
$hlog = New-LogFile ($scriptInfo.Name, $logFileName)

## PARAMETERS

### -scriptName
Name of the script/program to be used with logged messages.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $SCRIPT:ScriptName
Accept pipeline input: False
Accept wildcard characters: False
```

### -logName
Full Name of the file where messages will be written.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: $SCRIPT:LogFileName
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
