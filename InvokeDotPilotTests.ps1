# NOTE: `.\InvokeDotPilotTests.ps1 -Tags "Dotnet"`

[CmdletBinding()]
param (
    [Parameter()]
    [string[]]$Tags
)

. "$PSScriptRoot\Src\Config\Defaults.ps1"

$rootPath = Resolve-Path "$PSScriptRoot"
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
$config.Filter.Tag = $Tags

Invoke-Pester -Configuration $config
