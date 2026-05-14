param(
    [Alias("Dev")]
    [switch]$Development
)

function Add-ProfileRegion {
    param(
        [string]$ProfilePath,
        [string]$RegionName,
        [string]$Content
    )

    $profileContent = Get-Content $ProfilePath -Raw
    $regionStart = "#region $RegionName"
    $regionEnd = "#endregion $RegionName"
    $exists = $profileContent | `
        Select-String -Pattern ([regex]::Escape($regionStart))

    if ($exists) {
        Write-Host "$RegionName block already in profile. Skipping."
        return
    }

    $block = "$regionStart`n$Content`n$regionEnd"

    Add-Content -Path $ProfilePath -Value $block
    Write-Host "Added $RegionName block to profile."
}

$profilePath = $PROFILE

# Ensure profile exists
if (-not (Test-Path $profilePath)) {
    [void](New-Item -Path $profilePath -ItemType File -Force)
    Write-Host "Created profile: $profilePath"
}

Write-Host "Using profile: $profilePath"

$rootDir = Join-Path $PSScriptRoot ".."
$modulePath = (Resolve-Path $rootDir).Path

# Insider: add module path to PSModulePath
Add-ProfileRegion `
    -ProfilePath $profilePath `
    -RegionName "DotPilot Insider" `
    -Content @"
`$env:PSModulePath += "$([IO.Path]::PathSeparator)$modulePath"
"@

# Development only: auto-import modules when inside project directory
if ($Development) {
    Add-ProfileRegion `
        -ProfilePath $profilePath `
        -RegionName "DotPilot Development" `
        -Content @"
if (`$PWD.Path -like '$modulePath*') {
    Import-Module DotPilot.ProjectScaffold
    Import-Module DotPilot.Utilities
}
"@
}
