function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet("Info", "Warn", "Error", "Debug")]
        [string]$Level,

        [string]$Message,

        [string]$Source,

        [string]$File
    )

    Write-LogConsole -Level $Level -Message $Message

    if ($File) {
        $writeLogFileSplat = @{
            Level   = $Level
            Message = $Message
            Source  = $Source
            Path    = $File
        }
        Write-LogFile @writeLogFileSplat
    }
}
