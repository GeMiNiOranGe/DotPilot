---
external help file: DotPilot.Core-help.xml
Module Name: DotPilot.Core
online version: https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Write-Log.md
schema: 2.0.0
---

# Write-Log

## SYNOPSIS
Writes a log entry to a log file and the console.

## SYNTAX

```
Write-Log [-Level] <String> [[-Message] <String>] [[-OutputFile] <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The `Write-Log` function is used to log messages to a log file and the console.
It supports four log levels: Info, Warn, Error, and Debug.

## EXAMPLES

### EXAMPLE 1
```
Write-Log -Level Info -Message "This is an informational message."
```

Output
```powershell
2024-01-01 12:00:00 INFO	This is an informational message.
```

Appends the entry to the default log file and writes to the console.

### EXAMPLE 2
```
Write-Log -Level Error -Message "An error occurred." -OutputFile "C:\Logs\mylog.txt"
```

Output
```powershell
2024-01-01 12:00:00 ERROR	An error occurred.
```

Appends the entry to "C:\Logs\mylog.txt" and writes to the console.

## PARAMETERS

### -Level
Specifies the log level for the message.
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

### -OutputFile
Specifies the path to the log file.
If not provided, the log file will be created in the same directory as the script file, with the same name as the script file but with a ".log" extension.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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

### None. This function does not return any output, but it appends an entry to a log file and writes to the console.
## NOTES
This function is designed to be used in PowerShell scripts to provide a consistent and easy-to-use logging mechanism.

## RELATED LINKS

[Online version](https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Write-Log.md)

[Write-ConsoleLog]()



