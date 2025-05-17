. $PSScriptRoot\Utilities.ps1

function New-LayeredDotnetTemplate {
    param (
        [string]$OutputPath
    )

    $template = @'
{
    "solutionName": "MySolution",
    "layers": [
        {
            "name": "LayerOne",
            "type": "classlib"
        },
        {
            "name": "LayerTwo",
            "type": "classlib",
            "projects": [
                "LayerOne"
            ]
        },
        {
            "name": "LayerThree",
            "type": "webapi",
            "extraArguments": "--use-controllers",
            "packages": [
                "NSwag.AspNetCore",
                "Scalar.AspNetCore"
            ],
            "projects": [
                "LayerThree"
            ]
        }
    ]
}
'@
    $targetOutputPath = `
        if ($OutputPath) { $OutputPath } `
        else { ".\layers.template.json" }
    $directory = [System.IO.Path]::GetDirectoryName($targetOutputPath)

    if ($directory -ne "" -and -not (Test-Path $directory)) {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension(
            $MyInvocation.MyCommand.Path
        )

        throw [System.IO.DirectoryNotFoundException]::new(
            "$fileName : The directory '$directory' does not exist."
        )
    }

    Set-Content -Path $targetOutputPath -Value $template -Encoding UTF8
    Write-ConsoleLog Info "Template created successfully at: $targetOutputPath"
}
