. $PSScriptRoot\..\DotPilot.Core\Src\Public\Write-ConsoleLog.ps1

$docsPath = "$PSScriptRoot\..\Docs"

if (-not (Get-Module -ListAvailable -Name platyPS)) {
    Install-Module -Name platyPS -Scope CurrentUser -RequiredVersion 0.14.2
}

Import-Module platyPS

$modules = @(
    @{
        Name = "DotPilot.Core"
        Path = "$PSScriptRoot\..\DotPilot.Core\Src\DotPilot.Core.psd1"
    }
    @{
        Name = "DotPilot.ProjectScaffold"
        Path = "$PSScriptRoot\..\DotPilot.ProjectScaffold\Src\DotPilot.ProjectScaffold.psd1"
    }
)

foreach ($module in $modules) {
    $modulePath = $module.Path
    $moduleName = $module.Name

    $remoteDocsUrl = (
        Import-PowerShellDataFile -Path $modulePath
    ).PrivateData.PSData.ProjectUri + "/blob/main/Docs"

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
}

Write-ConsoleLog Info "Removed escape characters from documentation files."
