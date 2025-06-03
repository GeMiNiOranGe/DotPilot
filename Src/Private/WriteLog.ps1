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
Writes an informational message to the log file and the console.

.EXAMPLE
Write-Log -Level Error -Message "An error occurred." -OutputFile "C:\Logs\mylog.txt"
Writes an error message to the log file "C:\Logs\mylog.txt" and the console.

.NOTES
This function is designed to be used in PowerShell scripts to provide a consistent and easy-to-use logging mechanism.
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
    Write-ConsoleLog -Level $Level $Message
}
