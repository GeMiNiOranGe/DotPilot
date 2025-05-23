$profilePath = $PROFILE

if (-not (Test-Path $profilePath)) {
    New-Item -Path $profilePath -ItemType File -Force | Out-Null
    Write-Host "Created a new file profile: $profilePath"
}

$profileContent = Get-Content $profilePath
$pattern = "Import-Module\s+$($PSScriptRoot.Replace('\', '\\'))"
$aliasExists = $profileContent | Select-String -Pattern $pattern

if ($aliasExists) {
    Write-Host "Module 'DotPilot' existed in profile."
}
else {
    Add-Content `
        -Path $profilePath `
        -Value "Import-Module $PSScriptRoot"
    Write-Host "Imported 'DotPilot' into profile."
}
