---
external help file: DotPilot.Core-help.xml
Module Name: DotPilot.Core
online version: https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Write-Log.md
schema: 2.0.0
---

# Write-Log

## SYNOPSIS
Writes a log message to the console and optionally to a file.

## SYNTAX

```
Write-Log [-Level] <String> [[-Message] <String>] [-Source <String>] [-File <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The `Write-Log` function is a convenience wrapper around `Write-LogConsole` and `Write-LogFile`.
It always writes to the console, and additionally writes to a file if the `-File` parameter is provided.

## EXAMPLES

### EXAMPLE 1
```
Write-Log -Level Info -Message "Starting process."
```

Output
```powershell
info Starting process.
```

Writes the message to the console only.

### EXAMPLE 2
```
Write-Log -Level Error -Message "Something failed." -File "C:\Logs\run.log" -Source $MyInvocation.MyCommand.Name
```

Output
```powershell
error Something failed.
```

Writes the message to the console and appends an entry to "C:\Logs\run.log".

## PARAMETERS

### -Level
Specifies the level of the log message.
Valid values are "Info", "Warn", "Error", and "Debug".

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

### -Message
Specifies the message to be logged.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Source
Specifies the name of the caller to include in the file log entry as a label.
Has no effect if `-File` is not provided.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -File
Specifies the path to the log file.
If provided, the log entry will be appended to this file via `Write-LogFile`.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You can't pipe objects to `Write-Log`.
## OUTPUTS

### None. This function does not return any output.
## NOTES
- To write to the console only, omit the `-File` parameter.
- To write to a file, pass the `-File` parameter.

## RELATED LINKS

[Online version](https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Write-Log.md)



