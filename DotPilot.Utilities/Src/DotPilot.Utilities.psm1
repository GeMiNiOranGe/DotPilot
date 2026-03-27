# Directory entry order
$loadOrder = @('Public')

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
