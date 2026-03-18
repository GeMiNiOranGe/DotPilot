function Assert-ParentDirectoryExists {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCmdlet]$Cmdlet
    )

    $parentDir = [System.IO.Path]::GetDirectoryName($Path)
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
