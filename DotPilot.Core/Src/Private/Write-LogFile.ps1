function Write-LogFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [LogLevel]$Level,

        [Parameter(Position = 1)]
        [string]$Message,

        [string]$Source,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Path
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Omit the prefix entirely when Source is not provided.
    $sourceLabel = [string]::IsNullOrWhiteSpace($Source) ? "" : "${Source}: "

    # Format: "2000-01-01 12:00:00 INFO\t<Source: ><Message>"
    # Tab separates the level from the body for easier parsing.
    $entry = "$timestamp $($Level.ToString().ToUpper())`t$sourceLabel$Message"

    Add-Content -Path $Path -Value $entry
}
