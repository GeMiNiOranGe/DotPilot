<#
.SYNOPSIS
Creates a JSON template for a layered .NET project.

.DESCRIPTION
The `New-LayeredDotnetTemplate` function generates a JSON template file that can be used as a starting point for creating a layered .NET project. The template can be customized with different project architectures and solution names.

.PARAMETER OutputPath
Specifies the output path for the generated JSON template file. If not provided, the file will be created in the current directory with the name "layers.template.json".

.PARAMETER Architecture
Specifies the architecture of the layered project. Currently, the only supported value is "Clean".

.PARAMETER SolutionName
Specifies the name of the solution for the layered project. The default value is "Example".

.EXAMPLE
New-LayeredDotnetTemplate

.EXAMPLE
New-LayeredDotnetTemplate -OutputPath 'C:\Projects\MyProject\template.json' -Architecture Clean -SolutionName 'MyProject'

.NOTES
The generated JSON template file will have the following structure:

{
    "solutionName": "{{solutionName}}",
    "layers": [
        {
            "name": "LayerOne",
            "type": "classlib"
        },
        {
            "name": "LayerTwo",
            "type": "classlib",
            "extraArguments": [
                "--framework", "net6.0"
            ]
            "projectReferences": [
                "LayerOne"
            ]
        },
        {
            "name": "LayerThree",
            "type": "webapi",
            "extraArguments": "",
            "packages": [],
            "projectReferences": [
                "LayerThree"
            ]
        }
    ]
}

The template can be customized by modifying the "layers" array to include the desired project structure and configurations.
#>
function New-LayeredDotnetTemplate {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrWhiteSpace()]
        [string]$OutputPath,

        [ValidateSet("Clean")]
        [string]$Architecture,

        [ValidateNotNullOrWhiteSpace()]
        [string]$SolutionName = "Example"
    )
    $targetOutputPath = $OutputPath ? $OutputPath : ".\layers.template.json"
    $directory = [System.IO.Path]::GetDirectoryName($targetOutputPath)

    if ($directory -ne "" -and -not (Test-Path $directory)) {
        $exception = [System.IO.DirectoryNotFoundException]::new(
            "The directory '$directory' does not exist."
        )
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            $exception,
            "DirectoryNotFound",
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $OutputPath
        )
        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    $template = switch ($Architecture) {
        "Clean" {
            "CleanArchitecture.template.json"
            break
        }
        default {
            "DefaultLayers.template.json"
            break
        }
    }
    $templateContent = Get-Content -Raw `
        -Path "$PSScriptRoot\..\Template\Dotnet\$template"
    $templateContent = $templateContent -replace "{{solutionName}}", $SolutionName

    Set-Content -Path $targetOutputPath -Value $templateContent
    Write-ConsoleLog Info "Template created successfully at: $targetOutputPath"
}
