function Write-LogFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [LogLevel]$Level,

        [Parameter(Position = 1)]
        [string]$Message,

        # Source is optional for log file entries, but if provided, it must not
        # be null or whitespace. Cannot use [ValidateNotNullOrWhiteSpace()] here
        # because Source is not mandatory.
        [string]$Source,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Path
    )

    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

    # Omit the prefix entirely when Source is not provided.
    $sourceLabel = -not [string]::IsNullOrWhiteSpace($Source) `
        ? "${Source}: " `
        : ""

    # Format: "2000-01-01 12:00:00 INFO\t<Source: ><Message>"
    # Tab separates the level from the body for easier parsing.
    $entry = "$timestamp $($Level.ToString().ToUpper())`t$sourceLabel$Message"

    Add-Content -Path $Path -Value $entry
}
