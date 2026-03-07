<#
.SYNOPSIS
Writes a log entry to a log file and the console.

.DESCRIPTION
The `Write-Log` function is used to log messages to a log file and the console. It supports four log levels: Info, Warn, Error, and Debug.

.PARAMETER Level
Specifies the log level for the message. Valid values are "Info", "Warn", "Error", and "Debug".

.PARAMETER Message
Specifies the message to be logged.

.PARAMETER OutputFile
Specifies the path to the log file. If not provided, the log file will be created in the same directory as the script file, with the same name as the script file but with a ".log" extension.

.EXAMPLE
Write-Log -Level Info -Message "This is an informational message."

Output
```powershell
2024-01-01 12:00:00 INFO	This is an informational message.
```

Appends the entry to the default log file and writes to the console.

.EXAMPLE
Write-Log -Level Error -Message "An error occurred." -OutputFile "C:\Logs\mylog.txt"

Output
```powershell
2024-01-01 12:00:00 ERROR	An error occurred.
```

Appends the entry to "C:\Logs\mylog.txt" and writes to the console.

.INPUTS
None. You can't pipe objects to `Write-Log`.

.OUTPUTS
None. This function does not return any output, but it appends an entry to a log file and writes to the console.

.NOTES
This function is designed to be used in PowerShell scripts to provide a consistent and easy-to-use logging mechanism.

.LINK
https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Write-Log.md

.LINK
Write-ConsoleLog
#>
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet("Info", "Warn", "Error", "Debug")]
        [string]$Level,

        [Parameter(Position = 1)]
        [string]$Message,

        [Parameter(Position = 2)]
        [string]$OutputFile
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $scriptFile = [System.IO.Path]::GetFileName($MyInvocation.PSCommandPath)
    $scriptLogFile = $scriptFile -replace '\.ps1$', '.log'

    # If OutputFile is not exist, then init OutputFile
    $OutputFile = if ($OutputFile) { $OutputFile } else { $scriptLogFile }

    # If OutputFile is not the current scriptLogFile, add a log prefix
    $fileName = if ($OutputFile -ne $scriptLogFile) { "[$($scriptFile)] " }

    $entry = "$($timestamp) $($Level.ToUpper())`t$($fileName)$($Message)"

    # Write into file log
    Add-Content -Path $OutputFile -Value $entry

    # Write on console
    Write-ConsoleLog -Level $Level -Message $Message
}
