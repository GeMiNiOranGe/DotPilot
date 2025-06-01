# Dot source classes/public/private
$classes = @(
    Get-ChildItem -Path (
        Join-Path -Path $PSScriptRoot -ChildPath 'Classes/*.ps1'
    ) -Recurse -ErrorAction Stop
)
$private = @(
    Get-ChildItem -Path (
        Join-Path -Path $PSScriptRoot -ChildPath 'Private/*.ps1'
    ) -Recurse -ErrorAction Stop
)
$public = @(
    Get-ChildItem -Path (
        Join-Path -Path $PSScriptRoot -ChildPath 'Public/*.ps1'
    )  -Recurse -ErrorAction Stop
)
$types = @(
    Get-ChildItem -Path (
        Join-Path -Path $PSScriptRoot -ChildPath 'Types/*.ps1'
    )  -Recurse -ErrorAction Stop
)

foreach ($import in @($classes + $private + $public + $types)) {
    try {
        . $import.FullName
    }
    catch {
        throw "Unable to dot source [$($import.FullName)]"
    }
}

Export-ModuleMember -Function $public.Basename
