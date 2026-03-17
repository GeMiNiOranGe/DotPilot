function Write-LogConsole {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet("Info", "Warn", "Error", "Debug")]
        [string]$Level,

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

    $color = $colorMap[$Level]

    # NoNewline keeps the label and message on the same line.
    $writeHostSplat = @{
        Object          = $Level.ToLower()
        ForegroundColor = $color.ForegroundColor
        BackgroundColor = $color.BackgroundColor
        NoNewline       = $true
    }
    Write-Host @writeHostSplat
    Write-Host " $Message"
}
