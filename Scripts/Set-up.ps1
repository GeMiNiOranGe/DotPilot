$profilePath = $PROFILE

if (-not (Test-Path $profilePath)) {
    [void](New-Item -Path $profilePath -ItemType File -Force)
    Write-Host "Created a new file profile: $profilePath"
}

Write-Host "Using profile: $profilePath"

$rootDir = Join-Path $PSScriptRoot ".."
$moduleNames = @(
    "DotPilot.ProjectScaffold"
    "DotPilot.Utilities"
)

foreach ($moduleName in $moduleNames) {
    $profileContent = Get-Content $profilePath -Raw

    $modulePathRaw = Join-Path $rootDir $moduleName "$moduleName.psd1"
    $modulePath = (Resolve-Path $modulePathRaw).Path

    $importPattern = "Import-Module\s+$([regex]::Escape($modulePath))"
    $importExists = $profileContent | Select-String -Pattern $importPattern

    if ($importExists) {
        Write-Host "Module '$moduleName' already exists in profile."
    }
    else {
        Add-Content -Path $profilePath -Value "Import-Module $modulePath"
        Write-Host "Imported '$moduleName' into profile (as '$modulePath')."
    }
}
