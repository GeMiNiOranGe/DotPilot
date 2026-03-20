<#
.SYNOPSIS
Asserts that the parent directory of a given path exists, terminating the caller if it does not.

.DESCRIPTION
`Assert-ParentDirectoryExists` checks whether the parent directory of the specified path exists on the filesystem. If the parent directory is not found, the function throws a terminating `DirectoryNotFoundException` through the caller's `$PSCmdlet`, ensuring the error is attributed to the calling command rather than to this function.

This function is intended to be used as a guard clause inside advanced functions before performing file write operations.

.EXAMPLE
function Write-Something {
    [CmdletBinding()]
    param (
        [string]$Path
    )
    Assert-ParentDirectoryExists -Path $Path -Cmdlet $PSCmdlet
    # ... proceed with write
}

And then calling:
```powershell
Write-Something -Path "C:\Logs\app.log"
```

If "C:\Logs" does not exist, the error is reported as originating from `Write-Something`, not from `Assert-ParentDirectoryExists`.

.PARAMETER Path
Specifies the full path whose parent directory will be validated.

.PARAMETER Cmdlet
Specifies the `$PSCmdlet` object of the calling function. Used to throw the terminating error in the caller's context via `ThrowTerminatingError`.

.INPUTS
None. You can't pipe objects to `Assert-ParentDirectoryExists`.

.OUTPUTS
None. This function does not return any output.

.NOTES
`ThrowTerminatingError` is used instead of `throw` so that the error appears to originate from the caller, not from this function.

.LINK
https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Assert-ParentDirectoryExists.md
#>
function Assert-ParentDirectoryExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCmdlet]$Cmdlet
    )

    $parentDir = [System.IO.Path]::GetDirectoryName($Path)

    if ([string]::IsNullOrEmpty($parentDir)) {
        return
    }

    $fullPath = [System.IO.Path]::GetFullPath($Path)

    if (-not (Test-Path -Path $parentDir -PathType Container)) {
        $exception = [System.IO.DirectoryNotFoundException]::new(
            "Could not find a part of the path '$fullPath'." +
            " Ensure that the parent directory '$parentDir' exists."
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
