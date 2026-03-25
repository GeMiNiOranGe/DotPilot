<#
.SYNOPSIS
Asserts that a specified CLI tool is installed and available, terminating the caller if it is not.

.DESCRIPTION
`Assert-CliInstalled` checks whether a specified command is available on the system via `Get-Command`. If the command is not found, the function throws a terminating `CommandNotFoundException` through the caller's `$PSCmdlet`, ensuring the error is attributed to the calling command rather than to this function.

This function is intended to be used as a guard clause inside advanced functions before performing operations that depend on external CLI tools.

.EXAMPLE
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

And then calling:
```powershell
Invoke-DotnetBuild -ProjectPath "C:\MyProject"
```

If 'dotnet' is not found on the system, the error is reported as originating from `Invoke-DotnetBuild`, not from `Assert-CliInstalled`.

.PARAMETER Name
Specifies the name of the CLI tool to check for.

.PARAMETER Cmdlet
Specifies the `$PSCmdlet` object of the calling function. Used to throw the terminating error in the caller's context via `ThrowTerminatingError`.

.PARAMETER ExtraMessage
Specifies an optional message appended to the error output. Use this to provide installation hints or additional context.

.INPUTS
None. You can't pipe objects to `Assert-CliInstalled`.

.OUTPUTS
None. This function does not return any output.

.NOTES
`ThrowTerminatingError` is used instead of `throw` so that the error appears to originate from the caller, not from this function.

.LINK
https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Assert-CliInstalled.md
#>
function Assert-CliInstalled {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCmdlet]$Cmdlet,

        [string]$ExtraMessage
    )

    if (Get-Command -Name $Name -ErrorAction SilentlyContinue) {
        return
    }

    $exception = $ExtraMessage `
        ? [CommandNotFoundException]::new($Name, $ExtraMessage) `
        : [CommandNotFoundException]::new($Name)
    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
        $exception,
        "CommandNotFound",
        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
        $Name
    )

    $Cmdlet.ThrowTerminatingError($errorRecord)
}
