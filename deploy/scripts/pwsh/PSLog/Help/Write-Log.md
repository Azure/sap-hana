---
external help file: PSLog-help.xml
Module Name: PSLog
online version:
schema: 2.0.0
---

# Write-Log

## SYNOPSIS
Write a message to the Log file.

## SYNTAX

```
Write-Log [[-scriptName] <String>] [[-logName] <String>] [-severity] <Int32> [-message] <String>
 [<CommonParameters>]
```

## DESCRIPTION
Logs a message to the logfile if the severity is higher than or equal to $LogLevel.
Default severity level is information.

## EXAMPLES

### EXAMPLE 1
```
Write-Log $MSGTYPE_ERROR "Something has gone terribly wrong!"
```

## PARAMETERS

### -scriptName
Name of the script/program to be used with logged messages.
Use the $MSGTYPE_XXXX constants.

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

### -severity
The severity of the message. 
Can be Information, Warning, or Error.
Use the $MSGTYPE_XXXX constants.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -message
A string to be printed to the log.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
