function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet("Info", "Warn", "Error", "Debug")]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet("File", "Console")]
        [string[]]$Targets,

        [string]$Source,

        [string]$Path
    )

    if ("File" -in $Targets) {
        $writeLogSplat = @{
            Level   = $Level
            Message = $Message
            Source  = $Source
            Path    = $Path
        }
        Write-LogFile @writeLogSplat
    }

    if ("Console" -in $Targets) {
        $writeLogConsoleSplat = @{
            Level   = $Level
            Message = $Message
        }
        Write-LogConsole @writeLogConsoleSplat
    }
}
