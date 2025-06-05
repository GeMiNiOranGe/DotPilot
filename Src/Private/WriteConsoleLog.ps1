<#
.SYNOPSIS
Writes a console log message with a specified level.

.DESCRIPTION
The `Write-ConsoleLog` function is used to write console log messages with different levels, such as "Info", "Warn", "Error", and "Debug". Each level is displayed with a unique color scheme for better visibility.

.PARAMETER Level
Specifies the level of the log message. Valid values are "Info", "Warn", "Error", and "Debug".

.PARAMETER Message
Specifies the message to be written to the console.

.EXAMPLE
Write-ConsoleLog -Level Info -Message "This is an informational message."

.NOTES
This function is designed to provide a consistent and visually appealing way to log messages to the console.
#>
function Write-ConsoleLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet("Info", "Warn", "Error", "Debug")]
        [string]$Level,

        [Parameter(Position = 1)]
        [string]$Message
    )

    $colorMap = @{
        "Info"  = @{ ForegroundColor = "Black"; BackgroundColor = "Cyan" }
        "Warn"  = @{ ForegroundColor = "Black"; BackgroundColor = "Yellow" }
        "Error" = @{ ForegroundColor = "Black"; BackgroundColor = "Red" }
        "Debug" = @{ ForegroundColor = "Black"; BackgroundColor = "White" }
    }

    $color = $colorMap[$Level]

    $writeHostSplat = @{
        Level           = $Level.ToLower()
        ForegroundColor = $color.ForegroundColor
        BackgroundColor = $color.BackgroundColor
        NoNewline       = $true
    }
    Write-Host @writeHostSplat
    Write-Host " $($Message)"
}
