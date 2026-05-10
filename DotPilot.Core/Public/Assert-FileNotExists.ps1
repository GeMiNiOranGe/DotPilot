<#
.SYNOPSIS
Asserts that a specified file does not exist, terminating the caller if it does.

.DESCRIPTION
`Assert-FileNotExists` checks whether the specified path exists on the filesystem as a file. If the file is found, the function throws a terminating `FileAlreadyExistsException` through the caller's `$PSCmdlet`, ensuring the error is attributed to the calling command rather than to this function.

This function is intended to be used as a guard clause inside advanced functions before performing operations that require a file to be absent — such as creating a new file, initialising a config, or preventing accidental overwrites.

.EXAMPLE
function New-Config {
    [CmdletBinding()]
    param (
        [string]$Path
    )
    Assert-FileNotExists `
        -Path $Path `
        -Cmdlet $PSCmdlet `
        -Reason "Remove the existing file or choose a different path before running this command."
    # ... proceed with creation
}

And then calling:
```powershell
New-Config -Path "C:\Config\app.json"
```

If "C:\Config\app.json" already exists, the error is reported as originating from `New-Config`, not from `Assert-FileNotExists`.

.PARAMETER Path
Specifies the full path of the file to validate.

.PARAMETER Cmdlet
Specifies the `$PSCmdlet` object of the calling function. Used to throw the terminating error in the caller's context via `ThrowTerminatingError`.

.PARAMETER Reason
Specifies an optional message appended to the error output. Use this to provide remediation hints or additional context about why the file must not exist.

.INPUTS
None. You can't pipe objects to `Assert-FileNotExists`.

.OUTPUTS
None. This function does not return any output.

.NOTES
`ThrowTerminatingError` is used instead of `throw` so that the error appears to originate from the caller, not from this function.

.LINK
https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Assert-FileNotExists.md
#>
function Assert-FileNotExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCmdlet]$Cmdlet,

        [string]$Reason
    )

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        return
    }

    $filePath = [System.IO.Path]::GetFullPath($Path)

    $exception = [FileAlreadyExistsException]::new($filePath)
    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
        $exception,
        'FileAlreadyExists',
        [System.Management.Automation.ErrorCategory]::ResourceExists,
        $Path
    )

    if ($Reason) {
        $errorDetails = [System.Management.Automation.ErrorDetails]::new(
            $exception.Message + " $Reason"
        )
        $errorRecord.ErrorDetails = $errorDetails
    }

    $Cmdlet.ThrowTerminatingError($errorRecord)
}
