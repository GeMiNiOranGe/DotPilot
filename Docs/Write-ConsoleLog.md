---
external help file: DotPilot.Core-help.xml
Module Name: DotPilot.Core
online version: https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Write-ConsoleLog.md
schema: 2.0.0
---

# Write-ConsoleLog

## SYNOPSIS
Writes a console log message with a specified level.

## SYNTAX

```
Write-ConsoleLog [-Level] <String> [[-Message] <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The `Write-ConsoleLog` function is used to write console log messages with different levels, such as "Info", "Warn", "Error", and "Debug".
Each level is displayed with a unique color scheme for better visibility.

## EXAMPLES

### EXAMPLE 1
```
Write-ConsoleLog -Level Info -Message "This is an informational message."
```

Output
```powershell
info This is an informational message.
```

Writes "info" with a cyan background, then the message in default color.

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
Specifies the message to be written to the console.

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

### None. You can't pipe objects to `Write-ConsoleLog`.
## OUTPUTS

### None. This function does not return any output, but it writes a colored message to the console.
## NOTES
This function is designed to provide a consistent and visually appealing way to log messages to the console.

## RELATED LINKS

[Online version](https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Write-ConsoleLog.md)



