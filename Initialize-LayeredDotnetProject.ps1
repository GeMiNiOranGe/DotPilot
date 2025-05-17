. $PSScriptRoot\Utilities.ps1

function Initialize-LayeredDotnetProject {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TemplateJsonPath,
        [switch]$LogToFile
    )

    if (Test-WhiteSpace $TemplateJsonPath) {
        throw [System.Exception]::new(
            "Your string contains only spaces."
        )
    }

    # Load and parse JSON config
    if (-not (Test-Path $TemplateJsonPath)) {
        throw [System.Exception]::new(
            "Configuration file '$TemplateJsonPath' not found. " +
            "Use the `New-LayeredDotnetTemplate` command to create one if needed."
        )
    }

    try {
        $template = Get-Content -Raw -Path $TemplateJsonPath | ConvertFrom-Json
    }
    catch {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension(
            $MyInvocation.MyCommand.Path
        )

        throw [System.Exception]::new(
            "$fileName : Invalid JSON format in file '$TemplateJsonPath'."
        )
    }

    # Validate required fields
    if (-not $template.solutionName) {
        throw [System.Exception]::new(
            "Missing 'solutionName' in JSON template."
        )
    }

    if (-not $template.layers -or $template.layers.Count -eq 0) {
        throw [System.Exception]::new(
            "Missing or empty 'layers' array in JSON template."
        )
    }

    foreach ($layer in $template.layers) {
        if (-not $layer.name) {
            throw [System.Exception]::new(
                "Each layer must have a 'name' field."
            )
        }

        if (-not $layer.type) {
            throw [System.Exception]::new(
                "Each layer must have a 'type' field."
            )
        }
    }

    # Define the solution name
    $solutionName = $template.solutionName

    # Define layers and their types
    $layers = $template.layers

    $Log = if ($LogToFile) {
        {
            param($Level, $Message)
            Write-Log -Level $Level -Message $Message -OutputFile "$solutionName.log"
        }
    }
    else {
        {
            param($Level, $Message)
            Write-ConsoleLog -Level $Level -Message $Message
        }
    }

    # Create `Directory.Build.props` file
    Add-Content `
        -Path "Directory.Build.props" `
        -Value @(
        "<Project>",
        "  <ItemDefinitionGroup>",
        "    <ProjectReference>",
        "      <PrivateAssets>all</PrivateAssets>",
        "    </ProjectReference>",
        "  </ItemDefinitionGroup>",
        "</Project>"
    )

    # Create the `gitignore`
    & $Log Info "Creating gitignore"
    dotnet new gitignore

    # Create the Solution
    & $Log Info "Creating solution '$($solutionName)'"
    dotnet new sln --name $solutionName

    # Loop through each layer to create projects and add them to the solution
    foreach ($layer in $layers) {
        $projectName = "$($solutionName).$($layer.name)"
        $projectType = $layer.type
        $extraArguments = $layer.extraArguments

        $arguments = @("new", $projectType, "--name", $projectName)
        if ($extraArguments) {
            $arguments += $extraArguments
        }

        & $Log Info "Creating '$($projectName)' project"
        dotnet @arguments

        & $Log Info "Adding '$($projectName)' project to '$($solutionName).sln'"
        dotnet sln "$($solutionName).sln" add "$($projectName)/$($projectName).csproj"

        # Install NuGet packages if specified
        if ($layer.packages) {
            foreach ($package in $layer.packages) {
                & $Log Info "Installing '$($package)' for '$($projectName)'"
                dotnet add "$($projectName)/$($projectName).csproj" package $package
            }
        }
    }

    # Loop through each layer to reference projects
    foreach ($layer in $layers) {
        $projectName = "$($solutionName).$($layer.name)"

        if ($layer.projectReferences) {
            foreach ($projectReference in $layer.projectReferences) {
                & $Log Info "Adding reference '$($projectName)' project to '$($solutionName).$($projectReference)'"
                dotnet add $projectName reference "$($solutionName).$($projectReference)"
            }
        }
    }

    & $Log Info "Layered .NET project '$solutionName' initialized successfully!"
}
