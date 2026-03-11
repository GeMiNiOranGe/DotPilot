# Module-level default log file path; set this before calling Write-LogFile
# to enable file logging without passing -OutputFile
$script:DotPilotLogFile = $null

# Dot source classes/public/private
$classes = @(
    Get-ChildItem -Path (
        Join-Path -Path $PSScriptRoot -ChildPath 'Classes\*.ps1'
    ) -Recurse -ErrorAction Stop
)
$public = @(
    Get-ChildItem -Path (
        Join-Path -Path $PSScriptRoot -ChildPath 'Public\*.ps1'
    ) -Recurse -ErrorAction Stop
)

foreach ($import in @($classes + $public)) {
    try {
        . $import.FullName
    }
    catch {
        throw "Unable to dot source [$($import.FullName)]"
    }
}

Export-ModuleMember -Function $public.Basename
