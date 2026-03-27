# Load DotPilot.Core dependency via relative path
$corePsd1 = Join-Path `
    -Path $PSScriptRoot `
    -ChildPath "..\..\DotPilot.Core\Src\DotPilot.Core.psd1"
Import-Module -Name (Resolve-Path $corePsd1) -Force -Global

# Directory entry order
$loadOrder = @('Types', 'Config', 'Private', 'Public')

$files = $loadOrder | ForEach-Object {
    $getChildItemSplat = @{
        Path        = Join-Path -Path $PSScriptRoot -ChildPath "$_\*.ps1"
        Recurse     = $true
        ErrorAction = 'Stop'
    }
    Get-ChildItem @getChildItemSplat
}

# Dot source
foreach ($file in $files) {
    try {
        . $file.FullName
    }
    catch {
        throw "Unable to dot source [$($file.FullName)]"
    }
}
