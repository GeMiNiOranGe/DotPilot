---
external help file: DotPilot.Core-help.xml
Module Name: DotPilot.Core
online version: https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Assert-ParentDirectoryExists.md
schema: 2.0.0
---

# Assert-ParentDirectoryExists

## SYNOPSIS
Asserts that the parent directory of a given path exists, terminating the caller if it does not.

## SYNTAX

```
Assert-ParentDirectoryExists [-Path] <String> [-Cmdlet] <PSCmdlet> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
`Assert-ParentDirectoryExists` checks whether the parent directory of the specified path exists on the filesystem.
If the parent directory is not found, the function throws a terminating `DirectoryNotFoundException` through the caller's `$PSCmdlet`, ensuring the error is attributed to the calling command rather than to this function.

This function is intended to be used as a guard clause inside advanced functions before performing file write operations.

## EXAMPLES

### EXAMPLE 1
```
function Write-Something {
    [CmdletBinding()]
    param (
        [string]$Path
    )
    Assert-ParentDirectoryExists -Path $Path -Cmdlet $PSCmdlet
    # ... proceed with write
}
```

And then calling:
```powershell
Write-Something -Path "C:\Logs\app.log"
```

If "C:\Logs" does not exist, the error is reported as originating from `Write-Something`, not from `Assert-ParentDirectoryExists`.

## PARAMETERS

### -Path
Specifies the full path whose parent directory will be validated.

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

### None. You can't pipe objects to `Assert-ParentDirectoryExists`.
## OUTPUTS

### None. This function does not return any output.
## NOTES
`ThrowTerminatingError` is used instead of `throw` so that the error appears to originate from the caller, not from this function.

## RELATED LINKS

[Online version](https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Assert-ParentDirectoryExists.md)



