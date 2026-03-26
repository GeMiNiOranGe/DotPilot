<#
.SYNOPSIS
Initializes a layered .NET project based on a JSON template file.

.DESCRIPTION
The `Initialize-LayeredDotnetProject` function creates a new .NET solution and projects based on the template defined in a JSON file. The function supports creating multiple layers (projects) with different project types and optional NuGet package references.

.EXAMPLE
Initialize-LayeredDotnetProject -TemplateJsonPath '.\MyProject.template.json'

Output
```powershell
info Creating gitignore
The template "dotnet gitignore file" was created successfully.

info Creating solution 'MyProject'
The template "Solution File" was created successfully.

info Creating 'MyProject.Core' project
The template "Class Library" was created successfully.

# ...
# other console logs
# ...
```

Prints command messages during project initialization.

.PARAMETER TemplateJsonPath
Specifies the path to the JSON template file that defines the solution and project structure.

.PARAMETER NoDirectoryBuildFile
Specifies whether to skip creating the `Directory.Build.props` file.

.INPUTS
None. You can't pipe objects to `Initialize-LayeredDotnetProject`.

.OUTPUTS
None. This function does not return any output, but it creates a .NET solution and projects based on the provided template.

.NOTES
The JSON template file should be created using the `New-LayeredDotnetTemplate` command.

.LINK
https://github.com/GeMiNiOranGe/DotPilot/blob/main/Docs/Initialize-LayeredDotnetProject.md

.LINK
New-LayeredDotnetTemplate
#>
function Initialize-LayeredDotnetProject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$TemplateJsonPath,

        [switch]$NoDirectoryBuildFile
    )
    # Assert required CLI tools
    Assert-CommandExists -Name "dotnet" -Cmdlet $PSCmdlet

    # Load and parse JSON config
    $assertFileExistsSplat = @{
        Path         = $TemplateJsonPath
        Cmdlet       = $PSCmdlet
        ExtraMessage = (
            "Use the 'New-LayeredDotnetTemplate' command to create a template" +
            " if needed."
        )
    }
    Assert-FileExists @assertFileExistsSplat

    $templateJsonRaw = Get-Content -Raw -Path $TemplateJsonPath

    # Validate required fields
    try {
        $testJsonSplat = @{
            Json        = $templateJsonRaw
            SchemaFile  = "$PSScriptRoot\..\Schemas\LayeredDotnet.schema.json"
            ErrorAction = 'Stop'
        }
        [void](Test-Json @testJsonSplat)
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

    $template = [DotnetTemplate]($templateJsonRaw | ConvertFrom-Json)

    # Define variables
    $solutionName = $template.SolutionName
    $layers = $template.Layers
    $logSplat = @{
        Source   = $MyInvocation.MyCommand.Name
        FileName = $solutionName
    }

    # Create `Directory.Build.props` file
    if (-not $NoDirectoryBuildFile) {
        Set-Content -Path "Directory.Build.props" -Value @(
            '<Project>'
            '  <ItemDefinitionGroup>'
            '    <ProjectReference PrivateAssets="compile" />'
            '    <PackageReference PrivateAssets="compile" />'
            '  </ItemDefinitionGroup>'
            '</Project>'
        )
    }

    # Create the `gitignore`
    Write-Log Info "Creating gitignore" @logSplat
    dotnet new gitignore

    # Create the Solution
    Write-Log Info "Creating solution '$solutionName'" @logSplat
    dotnet new sln --name $solutionName

    # Loop through each layer to create projects and add them to the solution
    foreach ($layer in $layers) {
        $projectName = "$solutionName.$($layer.Name)"
        $projectType = $layer.Type
        $extraArguments = $layer.ExtraArguments

        $arguments = @("new", $projectType, "--name", $projectName)
        if ($extraArguments) {
            $arguments += $extraArguments
        }

        Write-Log Info "Creating '$projectName' project" @logSplat
        dotnet @arguments

        Write-Log Info "Adding '$projectName' project to '$solutionName.sln'" @logSplat
        dotnet sln "$solutionName.sln" add "$projectName/$projectName.csproj"

        # Install NuGet packages if specified
        foreach ($package in $layer.Packages) {
            Write-Log Info "Installing '$package' for '$projectName'" @logSplat
            dotnet add "$projectName/$projectName.csproj" package $package
        }
    }

    # Loop through each layer to reference projects
    foreach ($layer in $layers) {
        $projectName = "$solutionName.$($layer.Name)"

        foreach ($projectReference in $layer.ProjectReferences) {
            $projRef = "$solutionName.$projectReference"
            Write-Log Info "Adding reference '$projectName' project to '$projRef'" @logSplat
            dotnet add $projectName reference "$projRef"
        }
    }

    Write-Log Info "Layered .NET project '$solutionName' initialized successfully!" @logSplat
}
