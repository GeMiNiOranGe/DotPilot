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

<#
# Testcases
Write-Log Info "Test info" -OutputFile "info.log"
Write-Log Warn "Test warn" -OutputFile "Utilities.log"
Write-Log Error "Test error" -OutputFile "Remove-CleanArchitecture.log"
Write-Log Debug "Test debug"
 #>
