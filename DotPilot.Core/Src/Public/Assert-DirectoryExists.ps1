<#
.SYNOPSIS
Asserts that a specified directory exists, terminating the caller if it does not.

.DESCRIPTION
`Assert-DirectoryExists` checks whether the specified path exists on the filesystem as a directory. If the directory is not found, the function throws a terminating `DirectoryNotFoundException` through the caller's `$PSCmdlet`, ensuring the error is attributed to the calling command rather than to this function.

This function is intended to be used as a guard clause inside advanced functions before performing operations that depend on a directory being present.

.EXAMPLE
function Read-LogDirectory {
    [CmdletBinding()]
    param (
        [string]$Path
    )
    Assert-DirectoryExists -Path $Path -Cmdlet $PSCmdlet
    # ... proceed with read
}

And then calling:
```powershell
Read-LogDirectory -Path "C:\Logs"
```

If "C:\Logs" does not exist, the error is reported as originating from `Read-LogDirectory`, not from `Assert-DirectoryExists`.

.PARAMETER Path
Specifies the full path of the directory to validate.

.PARAMETER Cmdlet
Specifies the `$PSCmdlet` object of the calling function. Used to throw the terminating error in the caller's context via `ThrowTerminatingError`.

.INPUTS
None. You can't pipe objects to `Assert-DirectoryExists`.

.OUTPUTS
None. This function does not return any output.

.NOTES
`ThrowTerminatingError` is used instead of `throw` so that the error appears to originate from the caller, not from this function.

.LINK
https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Assert-DirectoryExists.md
#>
function Assert-DirectoryExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCmdlet]$Cmdlet
    )

    if (-not (Test-Path -Path $Path -PathType Container)) {
        $fullPath = [System.IO.Path]::GetFullPath($Path)
        $directoryName = [System.IO.Path]::GetFileName($Path)

        $exception = [System.IO.DirectoryNotFoundException]::new(
            "Could not find a part of the path '$fullPath'." +
            " Ensure that the directory '$directoryName' exists."
        )
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            $exception,
            'DirectoryNotFound',
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $Path
        )

        $Cmdlet.ThrowTerminatingError($errorRecord)
    }
}
