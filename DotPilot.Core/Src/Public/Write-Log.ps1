<#
.SYNOPSIS
Writes a log message to the console and optionally to a file.

.DESCRIPTION
The `Write-Log` function is a convenience wrapper around `Write-LogConsole` and `Write-LogFile`. It always writes to the console, and additionally writes to a file if the `-File` parameter is provided.

.EXAMPLE
Write-Log -Level Info -Message "Starting process."

Output
```powershell
info Starting process.
```

Writes the message to the console only.

.EXAMPLE
Write-Log -Level Error -Message "Something failed." -File "C:\Logs\run.log" -Source $MyInvocation.MyCommand.Name

Output
```powershell
error Something failed.
```

Writes the message to the console and appends an entry to "C:\Logs\run.log".

.PARAMETER Level
Specifies the level of the log message. Valid values are "Info", "Warn", "Error", and "Debug".

.PARAMETER Message
Specifies the message to be logged.

.PARAMETER Source
Specifies the name of the caller to include in the file log entry as a label. Has no effect if `-File` is not provided.

.PARAMETER File
Specifies the path to the log file. If provided, the log entry will be appended to this file via `Write-LogFile`.

.INPUTS
None. You can't pipe objects to `Write-Log`.

.OUTPUTS
None. This function does not return any output.

.NOTES
- To write to the console only, omit the `-File` parameter.
- To write to a file, pass the `-File` parameter.

.LINK
https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Write-Log.md
#>
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet("Info", "Warn", "Error", "Debug")]
        [string]$Level,

        [Parameter(Position = 1)]
        [string]$Message,

        [string]$Source,

        [string]$File
    )

    if ($File) {
        Assert-ParentDirectoryExists -Path $File -Cmdlet $PSCmdlet
    }

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
