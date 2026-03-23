<#
.SYNOPSIS
Writes a log message to the console and optionally to a file.

.DESCRIPTION
The `Write-Log` function is a convenience wrapper around `Write-LogConsole` and `Write-LogFile`. It always writes to the console, and additionally writes to a file if file logging is enabled via `$global:DotPilot.Log.FileLogging`.

.EXAMPLE
Write-Log -Level Info -Message "Starting process."

Output
```powershell
info Starting process.
```

Writes the message to the console only.

.EXAMPLE
Write-Log -Level Error -Message "Something failed." -FileName "run" -OutputDirectory "C:\Logs" -Source $MyInvocation.MyCommand.Name

Output
```powershell
error Something failed.
```

Writes the message to the console and, if `$global:DotPilot.Log.FileLogging` is enabled, appends an entry to "C:\Logs\run.log".

.PARAMETER Level
Specifies the level of the log message. Valid values are "Info", "Warn", "Error", and "Debug".

.PARAMETER Message
Specifies the message to be logged.

.PARAMETER Source
Specifies the name of the caller to include in the file log entry as a label. Has no effect if file logging is disabled.

.PARAMETER FileName
Specifies the base name (without extension) of the log file. The extension is determined automatically based on `$global:DotPilot.Log.FileFormat`. Has no effect if file logging is disabled.

.PARAMETER OutputDirectory
Specifies the directory where the log file will be written. If omitted, the current directory is used. Has no effect if file logging is disabled.

.INPUTS
None. You can't pipe objects to `Write-Log`.

.OUTPUTS
None. This function does not return any output.

.NOTES
- File logging is controlled by `$global:DotPilot.Log.FileLogging`. If it is `$false`, only console logging occurs regardless of other parameters.
- The log file format is controlled by `$global:DotPilot.Log.FileFormat`. Currently, only "Log" is supported.
- If file logging is enabled, `-FileName` must be provided, otherwise an error is thrown.
- If `-OutputDirectory` is provided and file logging is enabled, the directory is validated via `Assert-DirectoryExists` before writing.

.LINK
https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Write-Log.md
#>
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [LogLevel]$Level,

        [Parameter(Position = 1)]
        [string]$Message,

        [string]$Source,

        [string]$FileName,

        [string]$OutputDirectory
    )

    if (-not $FileName -and $global:DotPilot.Log.FileLogging) {
        $assertParameterExistsSplat = @{
            Name         = "FileName"
            Value        = $FileName
            Cmdlet       = $PSCmdlet
            ExtraMessage = "It is required when file logging is enabled."
        }
        Assert-ArgumentExists @assertParameterExistsSplat
    }

    if ($OutputDirectory -and $global:DotPilot.Log.FileLogging) {
        Assert-DirectoryExists -Path $OutputDirectory -Cmdlet $PSCmdlet
    }

    Write-LogConsole -Level $Level -Message $Message

    if (-not $global:DotPilot.Log.FileLogging) {
        return
    }

    switch ($global:DotPilot.Log.FileFormat) {
        "Log" {
            $extension = "log"
            $resolvedPath = if ($OutputDirectory) {
                Join-Path $OutputDirectory "$FileName.$extension"
            }
            else {
                # Current directory
                "$FileName.$extension"
            }
            $writeLogFileSplat = @{
                Level   = $Level
                Message = $Message
                Source  = $Source
                Path    = $resolvedPath
            }
            Write-LogFile @writeLogFileSplat
        }
        default {
            throw "Unsupported log file format: $(
                $global:DotPilot.Log.FileFormat
            )"
        }
    }
}
