<#
.SYNOPSIS
Asserts that a specified parameter value is not null or empty, terminating the caller if it is.

.DESCRIPTION
`Assert-ArgumentExists` checks whether the provided parameter value is null or empty. If the value is null or empty, the function throws a terminating `ArgumentException` through the caller's `$PSCmdlet`, ensuring the error is attributed to the calling command rather than to this function.

This function is intended to be used as a guard clause inside advanced functions to validate that required string parameters have been supplied with a meaningful value.

.EXAMPLE
function Invoke-Deploy {
    [CmdletBinding()]
    param (
        [string]$Environment
    )
    Assert-ArgumentExists `
        -Name 'Environment' `
        -Value $Environment `
        -Cmdlet $PSCmdlet `
        -ExtraMessage 'Specify a target environment such as "staging" or "production".'
    # ... proceed with deploy
}

And then calling:
```powershell
Invoke-Deploy -Environment ""
```

If 'Environment' is empty, the error is reported as originating from `Invoke-Deploy`, not from `Assert-ArgumentExists`.

.PARAMETER Name
Specifies the name of the parameter being validated. Used in the error message to identify which parameter is missing.

.PARAMETER Value
Specifies the value of the parameter being validated. Accepts empty strings so that the function itself can detect and reject them.

.PARAMETER Cmdlet
Specifies the `$PSCmdlet` object of the calling function. Used to throw the terminating error in the caller's context via `ThrowTerminatingError`.

.PARAMETER ExtraMessage
Specifies an optional message appended to the error output. Use this to provide usage hints or additional context about the expected value.

.INPUTS
None. You can't pipe objects to `Assert-ArgumentExists`.

.OUTPUTS
None. This function does not return any output.

.NOTES
- `ThrowTerminatingError` is used instead of `throw` so that the error appears to originate from the caller, not from this function.
- `[AllowEmptyString()]` is applied to `$Value` so that PowerShell does not reject empty strings before the function body can evaluate them.

.LINK
https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Assert-ArgumentExists.md
#>
function Assert-ArgumentExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCmdlet]$Cmdlet,

        [string]$ExtraMessage
    )

    if (-not [string]::IsNullOrEmpty($Value)) {
        return
    }

    $exception = [System.ArgumentException]::new(
        "Parameter '-$Name' must not be empty." + (
            $ExtraMessage ? " $ExtraMessage" : ""
        )
    )
    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
        $exception,
        "MissingRequiredParameter",
        [System.Management.Automation.ErrorCategory]::InvalidArgument,
        $Value
    )

    $Cmdlet.ThrowTerminatingError($errorRecord)
}
