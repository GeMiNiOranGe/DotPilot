<#
.SYNOPSIS
Writes a log entry to a log file and the console.

.DESCRIPTION
The `Write-LogFile` function is used to log messages to a log file and the console. It supports four log levels: Info, Warn, Error, and Debug.

.PARAMETER Level
Specifies the log level for the message. Valid values are "Info", "Warn", "Error", and "Debug".

.PARAMETER Message
Specifies the message to be logged.

.PARAMETER Path
Specifies the path to the log file. The log entry will be appended to this file.

.PARAMETER Source
Specifies the name of the caller to include in the log entry as a label. Use `$MyInvocation.MyCommand.Name` to pass the caller's function name automatically.

.EXAMPLE
Write-LogFile -Level Info -Message "This is an informational message." -Path "C:\Logs\mylog.txt"

Output
```powershell
2024-01-01 12:00:00 INFO	This is an informational message.
```

Appends the entry to "C:\Logs\mylog.txt" and writes to the console.

.EXAMPLE
Write-LogFile -Level Error -Message "An error occurred." -Path "C:\Logs\mylog.txt" -Source $MyInvocation.MyCommand.Name

Output
```powershell
2024-01-01 12:00:00 ERROR	Initialize-LayeredDotnetProject: An error occurred.
```

Appends the entry with a source label to "C:\Logs\mylog.txt" and writes to the console.

.INPUTS
None. You can't pipe objects to `Write-LogFile`.

.OUTPUTS
None. This function does not return any output, but it appends an entry to a log file and writes to the console.

.NOTES
This function is designed to be used in PowerShell scripts to provide a consistent and easy-to-use logging mechanism.

.LINK
https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Write-LogFile.md

.LINK
Write-LogConsole
#>
function Write-LogFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet("Info", "Warn", "Error", "Debug")]
        [string]$Level,

        [Parameter(Position = 1)]
        [string]$Message,

        [string]$Source,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Path
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $sourceLabel = -not [string]::IsNullOrWhiteSpace($Source) ?
        "${Source}: " :
        ""
    $entry = "$timestamp $($Level.ToUpper())`t$sourceLabel$Message"

    Add-Content -Path $Path -Value $entry
}
