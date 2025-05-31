. $PSScriptRoot\Src\Private\WriteConsoleLog.ps1

$moduleName = "DotPilot"
$modulePath = "$PSScriptRoot\Src\DotPilot.psd1"
$docsPath = "$PSScriptRoot\Docs"

$module = Import-PowerShellDataFile -Path $modulePath

$remoteDocsUrl = "$($module.PrivateData.PSData.ProjectUri)/blob/main/Docs"

if (-not (Get-Module -ListAvailable -Name platyPS)) {
    Install-Module -Name platyPS -Scope CurrentUser -RequiredVersion 0.14.2
}

Import-Module platyPS

Import-Module $modulePath -Force
New-MarkdownHelp -Module $moduleName -OutputFolder $docsPath -Force

# Remove escaped backticks from all '*.md' files
Get-ChildItem $docsPath -Filter *.md -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $content = $content -replace '\\`', '`'
    $content = $content -replace '\\\[', '['
    $content = $content -replace '\\\]', ']'
    $content = $content.Replace(
        "[$remoteDocsUrl/$($_.BaseName).md]($remoteDocsUrl/$($_.BaseName).md)",
        "[Online version]($remoteDocsUrl/$($_.BaseName).md)"
    )
    Set-Content $_.FullName -Value $content
}

Write-ConsoleLog Info "Removed escape characters from documentation files."
