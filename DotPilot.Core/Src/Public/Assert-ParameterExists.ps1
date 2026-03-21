function Assert-ParameterExists {
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

    if ([string]::IsNullOrEmpty($Value)) {
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
}
