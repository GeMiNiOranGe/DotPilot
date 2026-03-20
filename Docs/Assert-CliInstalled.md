---
external help file: DotPilot.Core-help.xml
Module Name: DotPilot.Core
online version: https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Assert-CliInstalled.md
schema: 2.0.0
---

# Assert-CliInstalled

## SYNOPSIS
Asserts that a specified CLI tool is installed and available, terminating the caller if it is not.

## SYNTAX

```
Assert-CliInstalled [-Name] <String> [-Cmdlet] <PSCmdlet> [[-ExtraMessage] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
`Assert-CliInstalled` checks whether a specified command is available on the system via `Get-Command`.
If the command is not found, the function throws a terminating `CliToolNotInstalledException` through the caller's `$PSCmdlet`, ensuring the error is attributed to the calling command rather than to this function.

This function is intended to be used as a guard clause inside advanced functions before performing operations that depend on external CLI tools.

## EXAMPLES

### EXAMPLE 1
```
function Invoke-DotnetBuild {
    [CmdletBinding()]
    param (
        [string]$ProjectPath
    )
    Assert-CliInstalled `
        -Name 'dotnet' `
        -Cmdlet $PSCmdlet `
        -ExtraMessage 'Make sure the .NET SDK is installed.'
    # ... proceed with build
}
```

And then calling:
```powershell
Invoke-DotnetBuild -ProjectPath "C:\MyProject"
```

If 'dotnet' is not found on the system, the error is reported as originating from `Invoke-DotnetBuild`, not from `Assert-CliInstalled`.

## PARAMETERS

### -Name
Specifies the name of the CLI tool to check for.

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
Specifies the `$PSCmdlet` object of the calling function.
Used to throw the terminating error in the caller's context via `ThrowTerminatingError`.

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
Specifies an optional message appended to the error output.
Use this to provide installation hints or additional context.

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

### None. This function does not return any output.
## NOTES
`ThrowTerminatingError` is used instead of `throw` so that the error appears to originate from the caller, not from this function.

## RELATED LINKS

[Online version](https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Assert-CliInstalled.md)



