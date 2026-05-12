# NOTE: `.\Scripts\InvokeDotPilotTests.ps1 -Tags "Dotnet"`

[CmdletBinding()]
param (
    [string[]]$Tags,

    [string[]]$Path
)

$rootDir = Resolve-Path "$PSScriptRoot\.."
$moduleNames = @(
    "DotPilot.Core"
    "DotPilot.ProjectScaffold"
)

foreach ($moduleName in $moduleNames) {
    $modulePath = Join-Path $rootDir $moduleName "$moduleName.psd1"
    Import-Module $modulePath -Force -ErrorAction Stop
}

if (-not (Get-Module -ListAvailable -Name Pester)) {
    throw @(
        "Pester is not installed. Install by: "
        "Install-Module -Name Pester -Force -RequiredVersion 5.7.1"
    ) -join ""
}
Import-Module Pester

$config = [PesterConfiguration]::new()
$config.Output.Verbosity = "Detailed"
$config.Filter.Tag = $Tags
$config.Run.Path = $Path ?? @(foreach ($moduleName in $moduleNames) {
    Join-Path $rootDir "Tests" $moduleName
})

Invoke-Pester -Configuration $config
