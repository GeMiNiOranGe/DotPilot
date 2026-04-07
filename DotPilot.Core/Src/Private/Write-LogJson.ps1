function Write-LogJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [LogLevel]$Level,

        [Parameter(Position = 1)]
        [string]$Message,

        [ValidateNotNullOrWhiteSpace()]
        [string]$Source,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Path
    )

    $entry = [ordered]@{
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        Level     = $Level.ToString()
        Message   = $Message
    }

    # Omit Source entirely when not provided,
    # consistent with Write-LogFile behavior.
    if ($Source) {
        $entry.Source = $Source
    }

    $json = $entry | ConvertTo-Json -Compress

    Add-Content -Path $Path -Value $json
}
