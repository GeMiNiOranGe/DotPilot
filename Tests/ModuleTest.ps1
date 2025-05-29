$rootPath = Resolve-Path "$PSScriptRoot\.."
$modulePath = Join-Path $rootPath "Src\DotPilot.psd1"

Import-Module $modulePath -Force -ErrorAction Stop

if (-not (Get-Module -ListAvailable -Name Pester)) {
    throw (
        "Pester is not installed. Install by: " +
        "Install-Module -Name Pester -Force -RequiredVersion 5.7.1"
    )
}
Import-Module Pester

$config = [PesterConfiguration]::new()
$config.Output.Verbosity = "Detailed"

Invoke-Pester -Configuration $config
