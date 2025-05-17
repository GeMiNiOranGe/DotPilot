$profilePath = $PROFILE

if (-not (Test-Path $profilePath)) {
    New-Item -Path $profilePath -ItemType File -Force | Out-Null
    Write-Host "Created a new file profile: $profilePath"
}

$profileContent = Get-Content $profilePath
$pattern = "Import-Module\s+$($PSScriptRoot.Replace('\', '\\'))\\DotPilot\.psd1"
$aliasExists = $profileContent | Select-String -Pattern $pattern

if ($aliasExists) {
    Write-Host "Module 'DotPilot' existed in profile."
}
else {
    Add-Content `
        -Path $profilePath `
        -Value "Import-Module $PSScriptRoot\DotPilot.psd1"
    Write-Host "Imported 'DotPilot' into profile."
}
