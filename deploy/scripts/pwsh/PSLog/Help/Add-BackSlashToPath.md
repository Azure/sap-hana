---
external help file: PSLog-help.xml
Module Name: PSLog
online version:
schema: 2.0.0
---

# Add-BackSlashToPath

## SYNOPSIS
Add a backslash to any given path if it is missing.

## SYNTAX

```
Add-BackSlashToPath [[-Path] <Object>]
```

## DESCRIPTION
Powershell usually returns path without a backslash.
    This function takes care of that.
    We need not expose this to the environment.

## EXAMPLES

### EXAMPLE 1
```
Add-BackSlashToPath -Path "C:\Test-PS-1"
```

C:\Test-PS-1\

### EXAMPLE 2
```
Add-BackSlashToPath -Path C:\Windows\System32\
```

C:\Windows\System32\

### EXAMPLE 3
```
Add-BackSlashToPath -Path \\comp1\C$\Windows\System32
```

\\\\comp1\C$\Windows\System32\

## PARAMETERS

### -Path
{{ Fill Path Description }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
