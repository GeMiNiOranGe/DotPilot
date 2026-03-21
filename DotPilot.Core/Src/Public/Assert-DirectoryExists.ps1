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
