<#
.SYNOPSIS
Guard clause for validating required string parameters inside advanced functions.

.DESCRIPTION
`Assert-ArgumentExists` is intended to be called from within advanced functions that have access to `$PSCmdlet`. Calling it directly from the terminal with a synthetic `$PSCmdlet` will not produce clean error output.

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

    $exception = [ArgumentBlankException]::new($Name)
    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
        $exception,
        "ArgumentBlank",
        [System.Management.Automation.ErrorCategory]::InvalidArgument,
        $Value
    )

    if ($ExtraMessage) {
        $errorDetails = [System.Management.Automation.ErrorDetails]::new(
            $exception.Message + " $ExtraMessage"
        )
        $errorRecord.ErrorDetails = $errorDetails
    }

    $Cmdlet.ThrowTerminatingError($errorRecord)
}
