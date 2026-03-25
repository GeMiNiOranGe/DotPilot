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
        [LogLevel]::Info  = @{
            ForegroundColor = [ConsoleColor]::Black;
            BackgroundColor = [ConsoleColor]::Cyan
        }
        [LogLevel]::Warn  = @{
            ForegroundColor = [ConsoleColor]::Black;
            BackgroundColor = [ConsoleColor]::Yellow
        }
        [LogLevel]::Error = @{
            ForegroundColor = [ConsoleColor]::Black;
            BackgroundColor = [ConsoleColor]::Red
        }
        [LogLevel]::Debug = @{
            ForegroundColor = [ConsoleColor]::Black;
            BackgroundColor = [ConsoleColor]::White
        }
    }
    $color = $colorMap[$Level]

    # NoNewline keeps the label and message on the same line.
    $writeHostSplat = @{
        Object          = $Level.ToString().ToLower()
        ForegroundColor = $color.ForegroundColor
        BackgroundColor = $color.BackgroundColor
        NoNewline       = $true
    }
    Write-Host @writeHostSplat
    Write-Host " $Message"
}
