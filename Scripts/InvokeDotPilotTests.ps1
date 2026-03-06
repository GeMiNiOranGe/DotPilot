# NOTE: `.\Scripts\InvokeDotPilotTests.ps1 -Tags "Dotnet"`

[CmdletBinding()]
param (
    [Parameter()]
    [string[]]$Tags
)

. "$PSScriptRoot\..\DotPilot.ProjectScaffold\Src\Config\Defaults.ps1"

$rootPath = Resolve-Path "$PSScriptRoot\.."
$corePath = Join-Path $rootPath "DotPilot.Core\Src\DotPilot.Core.psd1"
$scaffoldPath = Join-Path $rootPath "DotPilot.ProjectScaffold\Src\DotPilot.ProjectScaffold.psd1"

Import-Module $corePath -Force -ErrorAction Stop
Import-Module $scaffoldPath -Force -ErrorAction Stop

if (-not (Get-Module -ListAvailable -Name Pester)) {
    throw (
        "Pester is not installed. Install by: " +
        "Install-Module -Name Pester -Force -RequiredVersion 5.7.1"
    )
}
Import-Module Pester

$config = [PesterConfiguration]::new()
$config.Output.Verbosity = "Detailed"
$config.Filter.Tag = $Tags
$config.Run.Path = @(
    "$rootPath\DotPilot.Core\Tests",
    "$rootPath\DotPilot.ProjectScaffold\Tests",
    "$rootPath\DotPilot.Utilities\Tests"
)

Invoke-Pester -Configuration $config
