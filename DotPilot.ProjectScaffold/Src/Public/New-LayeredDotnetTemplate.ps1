<#
.SYNOPSIS
Creates a JSON template for a layered .NET project.

.DESCRIPTION
The `New-LayeredDotnetTemplate` function generates a JSON template file that can be used as a starting point for creating a layered .NET project. The template can be customized with different project architectures and solution names.

.EXAMPLE
New-LayeredDotnetTemplate

Output
```
info Template created successfully at: .\Default.template.json
```

Creates the default template in the current directory.

.EXAMPLE
New-LayeredDotnetTemplate -OutputPath '.\MyProject.template.json' -Preset Clean -SolutionName 'MyProject'

Output
```
info Template created successfully at: .\MyProject.template.json
```

Creates a template with the Clean architecture in the current directory, with the file name "MyProject.template.json" and the solution name "MyProject".

.PARAMETER OutputPath
Specifies the output path for the generated JSON template file. If not provided, the file will be created in the current directory with the name "layers.template.json".

.PARAMETER Preset
Specifies the preset of the layered project.

.PARAMETER SolutionName
Specifies the name of the solution for the layered project. The default value is "Example".

.INPUTS
None. You can't pipe objects to `New-LayeredDotnetTemplate`.

.OUTPUTS
None. This function does not return any output, but it creates a JSON template file with the specified template.

.NOTES
The generated JSON template file will have the following structure:
```json
{
    "solutionName": "Example",
    "layers": [
        {
            "name": "App",
            "type": "webapi",
            "extraArguments": "--use-controllers",
            "packages": [],
            "projectReferences": []
        }
        // define other layers ...
    ]
}
```
The template can be customized by modifying the "layers" array to include the desired project structure and templates.

Property            | Type     | Description
------------------- | -------- | -----------------------------------------------------------------
`name`              | string   | The name of the project.
`type`              | string   | The type of project, `webapi` indicates it's a Web API project.
`extraArguments`    | string   | Additional command-line arguments used when creating the project.
`packages`          | array    | A list of NuGet packages that the project depends on.
`projectReferences` | array    | A list of other projects this project references.

.LINK
https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/New-LayeredDotnetTemplate.md
#>
function New-LayeredDotnetTemplate {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrWhiteSpace()]
        [string]$OutputPath,

        [ValidateSet("Clean", "WinFormsThreeLayers")]
        [string]$Preset,

        [ValidateNotNullOrWhiteSpace()]
        [string]$SolutionName = "Example"
    )
    $targetOutputPath = $OutputPath ? $OutputPath : $DefaultTemplateOutputPath

    Assert-ParentDirectoryExists -Path $targetOutputPath -Cmdlet $PSCmdlet

    $rawTemplate = switch ($Preset) {
        "Clean" {
            "CleanArchitecture.template.json"
            break
        }
        "WinFormsThreeLayers" {
            "WinFormsThreeLayersArchitecture.template.json"
            break
        }
        default {
            "DefaultArchitecture.template.json"
            break
        }
    }
    $templateDir = "$PSScriptRoot\..\Template\Dotnet"
    $template = Get-Content -Path "$templateDir\$rawTemplate" -Raw
    $template = $template -replace "{{solutionName}}", $SolutionName

    try {
        $setContentSplat = @{
            Path        = $targetOutputPath
            Value       = $template
            NoNewline   = $true
            ErrorAction = "Stop"
        }
        Set-Content @setContentSplat
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

    $logSplat = @{
        Source   = $MyInvocation.MyCommand.Name
        FileName = $solutionName
    }

    Write-Log Info "Template created successfully at '$targetOutputPath'" @logSplat
}
