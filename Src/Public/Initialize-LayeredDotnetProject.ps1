<#
.SYNOPSIS
Initializes a layered .NET project based on a JSON template file.

.DESCRIPTION
The `Initialize-LayeredDotnetProject` function creates a new .NET solution and projects based on the template defined in a JSON file. The function supports creating multiple layers (projects) with different project types and optional NuGet package references.

.PARAMETER TemplateJsonPath
Specifies the path to the JSON template file that defines the solution and project structure.

.PARAMETER NoDirectoryBuildFile
Specifies whether to skip creating the `Directory.Build.props` file.

.PARAMETER LogToFile
Specifies whether to log the output to a file instead of the console.

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

        [switch]$NoDirectoryBuildFile,

        [switch]$LogToFile
    )
    # Assert required CLI tools
    Assert-CliInstalled -CommandName "dotnet" -Cmdlet $PSCmdlet

    # Load and parse JSON config
    if (-not (Test-Path $TemplateJsonPath)) {
        $exception = [System.IO.FileNotFoundException]::new(
            "Template file '$TemplateJsonPath' not found. Use the " +
            "`New-LayeredDotnetTemplate` command to create one if needed."
        )
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            $exception,
            "FileNotFound",
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $TemplateJsonPath
        )
        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    $templateJsonRaw = Get-Content -Raw -Path $TemplateJsonPath

    # Validate required fields
    try {
        $null = Test-Json `
            -Json $templateJsonRaw `
            -SchemaFile "$PSScriptRoot\..\Schemas\LayeredDotnet.schema.json" `
            -ErrorAction Stop
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

    $template = [DotnetTemplate]($templateJsonRaw | ConvertFrom-Json)

    # Define variables
    $solutionName = $template.SolutionName
    $layers = $template.Layers
    $Log = $LogToFile ? {
        param($Level, $Message)
        Write-Log -Level $Level -Message $Message -OutputFile "$solutionName.log"
    } : {
        param($Level, $Message)
        Write-ConsoleLog -Level $Level -Message $Message
    }

    # Create `Directory.Build.props` file
    if (-not $NoDirectoryBuildFile) {
        Set-Content -Path "Directory.Build.props" -Value @(
            "<Project>",
            "  <ItemDefinitionGroup>",
            "    <ProjectReference>",
            "      <PrivateAssets>all</PrivateAssets>",
            "    </ProjectReference>",
            "  </ItemDefinitionGroup>",
            "</Project>"
        )
    }

    # Create the `gitignore`
    & $Log Info "Creating gitignore"
    dotnet new gitignore

    # Create the Solution
    & $Log Info "Creating solution '$solutionName'"
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

        & $Log Info "Creating '$projectName' project"
        dotnet @arguments

        & $Log Info "Adding '$projectName' project to '$solutionName.sln'"
        dotnet sln "$solutionName.sln" add "$projectName/$projectName.csproj"

        # Install NuGet packages if specified
        foreach ($package in $layer.Packages) {
            & $Log Info "Installing '$package' for '$projectName'"
            dotnet add "$projectName/$projectName.csproj" package $package
        }
    }

    # Loop through each layer to reference projects
    foreach ($layer in $layers) {
        $projectName = "$solutionName.$($layer.Name)"

        foreach ($projectReference in $layer.ProjectReferences) {
            $projRef = "$solutionName.$projectReference"
            & $Log Info "Adding reference '$projectName' project to '$projRef'"
            dotnet add $projectName reference "$projRef"
        }
    }

    & $Log Info "Layered .NET project '$solutionName' initialized successfully!"
}
