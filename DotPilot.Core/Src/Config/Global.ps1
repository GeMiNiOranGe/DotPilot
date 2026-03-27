if (-not (Get-Variable -Name 'DotPilot' -Scope Global -ErrorAction SilentlyContinue)) {
    $global:DotPilot = [PSCustomObject]@{
        Log = [PSCustomObject]@{
            FileLogging = $false
            FileFormat  = [LogFormat]::Log
        }
    }
}
