function Write-ConsoleLog {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
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
        [Parameter(Position = 0, Mandatory)]
        [ValidateSet("Info", "Warn", "Error", "Debug")]
        [string]$Level,

        [Parameter(Position = 1)]
        [string]$Message,

        [Parameter(Position = 2)]
        [string]$OutputFile
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $defaultLogFile = "Default.log"
    $scriptPath = $MyInvocation.PSCommandPath
    $scriptLogFile = "$(
        [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)
    ).log"

    # If OutputFile is not exist, then init OutputFile
    if (-not $OutputFile) {
        $OutputFile = `
            if ($scriptPath) { $scriptLogFile } `
            else { $defaultLogFile }
    }

    # If OutputFile is not the current scriptLogFile, add a log prefix
    if ($OutputFile -ne $scriptLogFile) {
        $fileName = "[$(
            if ($scriptPath) { Split-Path -Leaf $scriptPath }
            else { "Console" }
        )] "
    }

    # If OutputFile is the default file, then do not create a prefix in the log
    if ($OutputFile -eq $defaultLogFile) {
        $fileName = ""
    }

    $entry = "$($timestamp) [$($Level.ToLower())]`t$($fileName)$($Message)"

    # Write into file log
    Add-Content -Path $OutputFile -Value $entry

    # Write on console
    Write-ConsoleLog -Level $Level $Message
}

<# 
# Testcases
Write-Log Info "Test info" -OutputFile "info.log"
Write-Log Warn "Test warn" -OutputFile "Logger.log"
Write-Log Error "Test error" -OutputFile "Default.log"
Write-Log Debug "Test debug"

PS C:\Path_to_my_project> 
>> . .\Logger.ps1
>> Write-Log Info "Test info (From Console)" -OutputFile "info.log"
>> Write-Log Warn "Test warn (From Console)" -OutputFile "Logger.log"
>> Write-Log Error "Test error (From Console)" -OutputFile "Default.log"
>> Write-Log Debug "Test debug (From Console)"
 #>
