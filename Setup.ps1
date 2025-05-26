$profilePath = $PROFILE

if (-not (Test-Path $profilePath)) {
    New-Item -Path $profilePath -ItemType File -Force | Out-Null
    Write-Host "Created a new file profile: $profilePath"
}

$profileContent = Get-Content $profilePath
$modulePath = "$PSScriptRoot\Src\DotPilot.psd1"
$pattern = "Import-Module\s+$($modulePath.Replace('\', '\\'))"
$aliasExists = $profileContent | Select-String -Pattern $pattern

if ($aliasExists) {
    Write-Host "Module 'DotPilot' existed in profile."
}
else {
    Add-Content `
        -Path $profilePath `
        -Value "Import-Module $modulePath"
    Write-Host "Imported 'DotPilot' into profile."
}
