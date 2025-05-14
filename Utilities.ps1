. $PSScriptRoot\ConsoleCallException.ps1

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

    Write-Host $Level.ToLower() -NoNewline `
        -ForegroundColor $color.ForegroundColor `
        -BackgroundColor $color.BackgroundColor
    Write-Host " $($Message)"
}

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
    # Prevent usage from interactive terminal
    if (-not $MyInvocation.PSScriptRoot) {
        throw [ConsoleCallException]::new((Get-PSCallStack)[0].FunctionName)
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $scriptFile = Split-Path -Leaf $MyInvocation.PSCommandPath
    $scriptLogFile = $scriptFile -replace '\.ps1$', '.log'

    # If OutputFile is not exist, then init OutputFile
    $OutputFile = if (-not $OutputFile) { $scriptLogFile }

    # If OutputFile is not the current scriptLogFile, add a log prefix
    $fileName = if ($OutputFile -ne $scriptLogFile) { "[$($scriptFile)] " }

    $entry = "$($timestamp) $($Level.ToUpper())`t$($fileName)$($Message)"

    # Write into file log
    Add-Content -Path $OutputFile -Value $entry

    # Write on console
    Write-ConsoleLog -Level $Level $Message
}

<# 
# Testcases
Write-Log Info "Test info" -OutputFile "info.log"
Write-Log Warn "Test warn" -OutputFile "Utilities.log"
Write-Log Error "Test error" -OutputFile "Remove-CleanArchitecture.log"
Write-Log Debug "Test debug"
 #>
