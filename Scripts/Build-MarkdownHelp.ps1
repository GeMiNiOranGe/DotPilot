if (-not (Get-Module -ListAvailable -Name platyPS)) {
    Install-Module -Name platyPS -Scope CurrentUser -RequiredVersion 0.14.2
}

Import-Module platyPS

$rootDir = Join-Path $PSScriptRoot ".."
$docsDir = Join-Path $rootDir "Docs"
$moduleNames = @(
    "DotPilot.Core"
    "DotPilot.ProjectScaffold"
)

foreach ($moduleName in $moduleNames) {
    $modulePath = Join-Path $rootDir $moduleName "$moduleName.psd1"

    $remoteDocsUrl = (
        Import-PowerShellDataFile -Path $modulePath
    ).PrivateData.PSData.ProjectUri + "/blob/main/Docs"

    Import-Module $modulePath -Force
    New-MarkdownHelp -Module $moduleName -OutputFolder $docsDir -Force

    # Remove escaped backticks from all '*.md' files
    Get-ChildItem $docsDir -Filter *.md -Recurse | ForEach-Object {
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
}

Write-Log Info "Removed escape characters from documentation files."
