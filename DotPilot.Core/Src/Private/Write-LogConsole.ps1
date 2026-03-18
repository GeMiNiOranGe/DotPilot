function Write-LogConsole {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [LogLevel]$Level,

        [Parameter(Position = 1)]
        [string]$Message
    )

    # Black foreground ensures readable contrast across all background colors.
    $colorMap = @{
        "Info"  = @{ ForegroundColor = "Black"; BackgroundColor = "Cyan" }
        "Warn"  = @{ ForegroundColor = "Black"; BackgroundColor = "Yellow" }
        "Error" = @{ ForegroundColor = "Black"; BackgroundColor = "Red" }
        "Debug" = @{ ForegroundColor = "Black"; BackgroundColor = "White" }
    }

    $levelName = $Level.ToString()
    $color = $colorMap[$levelName]

    # NoNewline keeps the label and message on the same line.
    $writeHostSplat = @{
        Object          = $levelName.ToLower()
        ForegroundColor = $color.ForegroundColor
        BackgroundColor = $color.BackgroundColor
        NoNewline       = $true
    }
    Write-Host @writeHostSplat
    Write-Host " $Message"
}
