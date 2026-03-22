<#
.SYNOPSIS
Asserts that a specified file exists, terminating the caller if it does not.

.DESCRIPTION
`Assert-FileExists` checks whether the specified path exists on the filesystem as a file. If the file is not found, the function throws a terminating `FileNotFoundException` through the caller's `$PSCmdlet`, ensuring the error is attributed to the calling command rather than to this function.

This function is intended to be used as a guard clause inside advanced functions before performing operations that depend on a file being present.

.EXAMPLE
function Import-Config {
    [CmdletBinding()]
    param (
        [string]$Path
    )
    Assert-FileExists `
        -Path $Path `
        -Cmdlet $PSCmdlet `
        -ExtraMessage "Ensure the file has been created before running this command."
    # ... proceed with import
}

And then calling:
```powershell
Import-Config -Path "C:\Config\app.json"
```

If "C:\Config\app.json" does not exist, the error is reported as originating from `Import-Config`, not from `Assert-FileExists`.

.PARAMETER Path
Specifies the full path of the file to validate.

.PARAMETER Cmdlet
Specifies the `$PSCmdlet` object of the calling function. Used to throw the terminating error in the caller's context via `ThrowTerminatingError`.

.PARAMETER ExtraMessage
Specifies an optional message appended to the error output. Use this to provide remediation hints or additional context about the expected file.

.INPUTS
None. You can't pipe objects to `Assert-FileExists`.

.OUTPUTS
None. This function does not return any output.

.NOTES
`ThrowTerminatingError` is used instead of `throw` so that the error appears to originate from the caller, not from this function.

.LINK
https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Assert-FileExists.md
#>
function Assert-FileExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCmdlet]$Cmdlet,

        [string]$ExtraMessage
    )

    if (Test-Path -Path $Path -PathType Leaf) {
        return
    }

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fileName = [System.IO.Path]::GetFileName($Path)

    $exception = [System.IO.FileNotFoundException]::new(
        "File '$fullPath' not found. Ensure that '$fileName' exists." + (
            $ExtraMessage ? " $ExtraMessage" : ""
        )
    )
    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
        $exception,
        'FileNotFound',
        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
        $Path
    )

    $Cmdlet.ThrowTerminatingError($errorRecord)
}
