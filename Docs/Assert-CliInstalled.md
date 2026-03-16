---
external help file: DotPilot.Core-help.xml
Module Name: DotPilot.Core
online version: https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Assert-CliInstalled.md
schema: 2.0.0
---

# Assert-CliInstalled

## SYNOPSIS
Asserts that a specified command is installed and available.

## SYNTAX

```
Assert-CliInstalled [-Name] <String> [-Cmdlet] <PSCmdlet> [[-ExtraMessage] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The `Assert-CliInstalled` function checks if a specified command is installed and available on the system.
If the command is not found, it throws a terminating error with a custom error message.

## EXAMPLES

### EXAMPLE 1
```
Assert-CliInstalled -Cmdlet $PSCmdlet -Name 'dotnet' -ExtraMessage 'Make sure the .NET Core SDK is installed.'
```

No output is produced if 'dotnet' is installed.
If the tool is not found, a terminating `CliToolNotInstalledException` is thrown via `$Cmdlet`.

## PARAMETERS

### -Name
Specifies the name of the command to check for.

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

### -Cmdlet
Specifies the PowerShell cmdlet object that is calling this function.

```yaml
Type: PSCmdlet
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExtraMessage
Specifies an optional extra message to include in the error message.

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

### None. You can't pipe objects to `Assert-CliInstalled`.
## OUTPUTS

### None. This function does not return any output, but it throws a terminating error if the CLI tool is not installed.
## NOTES
This function is designed to be used within other PowerShell functions or cmdlets to ensure that required command-line tools are installed and available before proceeding with the operation.

## RELATED LINKS

[Online version](https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Assert-CliInstalled.md)



