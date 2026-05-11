$profilePath = $PROFILE

if (-not (Test-Path $profilePath)) {
    New-Item -Path $profilePath -ItemType File -Force | Out-Null
    Write-Host "Created a new file profile: $profilePath"
}

$profileContent = Get-Content $profilePath

$rootPath = Join-Path $PSScriptRoot ".."
$modulePaths = @(
    Join-Path $rootPath "DotPilot.ProjectScaffold" "Src" `
        "DotPilot.ProjectScaffold.psd1",
    Join-Path $rootPath "DotPilot.Utilities" "Src" "DotPilot.Utilities.psd1"
)

foreach ($modulePath in $modulePaths) {
    $pattern = "Import-Module\s+$($modulePath.Replace('\', '\\'))"
    $aliasExists = $profileContent | Select-String -Pattern $pattern
    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($modulePath)

    if ($aliasExists) {
        Write-Host "Module '$moduleName' existed in profile."
    }
    else {
        Add-Content `
            -Path $profilePath `
            -Value "Import-Module $modulePath"
        Write-Host "Imported '$moduleName' into profile."
    }
}
