---
external help file: PSLog-help.xml
Module Name: PSLog
online version:
schema: 2.0.0
---

# Switch-LogFile

## SYNOPSIS
Archive the log files for the script.

## SYNTAX

```
Switch-LogFile [-Name] <String> [[-Arch] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
The number of archive files we maintain is determined by the numArch parameter.
    Log file name is ProgramName.log.

## EXAMPLES

### EXAMPLE 1
```
Switch-LogFile -Name "C:\Test-PS-1\First.log" -Arch 10
```

## PARAMETERS

### -Name
{{ Fill Name Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Arch
{{ Fill Arch Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
