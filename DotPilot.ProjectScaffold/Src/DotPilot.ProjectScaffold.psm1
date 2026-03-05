# Load DotPilot.Core dependency via relative path
$corePsd1 = Join-Path `
    -Path $PSScriptRoot `
    -ChildPath "..\..\DotPilot.Core\Src\DotPilot.Core.psd1"
Import-Module -Name (Resolve-Path $corePsd1) -Force -Global

# Dot source classes/public/private
$public = @(
    Get-ChildItem -Path (
        Join-Path -Path $PSScriptRoot -ChildPath 'Public\*.ps1'
    ) -Recurse -ErrorAction Stop
)
$config = @(
    Get-ChildItem -Path (
        Join-Path -Path $PSScriptRoot -ChildPath 'Config\*.ps1'
    ) -Recurse -ErrorAction Stop
)
$types = @(
    Get-ChildItem -Path (
        Join-Path -Path $PSScriptRoot -ChildPath 'Types\*.ps1'
    ) -Recurse -ErrorAction Stop
)

foreach ($import in @($public + $config + $types)) {
    try {
        . $import.FullName
    }
    catch {
        throw "Unable to dot source [$($import.FullName)]"
    }
}

Export-ModuleMember -Function $public.Basename
