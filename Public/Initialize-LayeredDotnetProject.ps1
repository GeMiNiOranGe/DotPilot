function Initialize-LayeredDotnetProject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$TemplateJsonPath,
        [switch]$NoDirectoryBuildFile,
        [switch]$LogToFile
    )
    # Load and parse JSON config
    if (-not (Test-Path $TemplateJsonPath)) {
        $exception = [System.IO.FileNotFoundException]::new(
            "Configuration file '$TemplateJsonPath' not found. Use the " +
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

    try {
        $template = Get-Content -Raw -Path $TemplateJsonPath | ConvertFrom-Json
    }
    catch {
        $exception = [System.IO.InvalidDataException]::new(
            "Invalid JSON format in file '$TemplateJsonPath'."
        )
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            $exception,
            "InvalidJson",
            [System.Management.Automation.ErrorCategory]::InvalidData,
            $TemplateJsonPath
        )
        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    # Validate required fields
    if (-not $template.solutionName) {
        $exception = [System.Exception]::new(
            "Missing 'solutionName' in JSON template."
        )
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            $exception,
            "MissingSolutionName",
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $template.solutionName
        )
        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    if (-not $template.layers -or $template.layers.Count -eq 0) {
        $exception = [System.Exception]::new(
            "Missing or empty 'layers' array in JSON template."
        )
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            $exception,
            "MissingOrEmptyLayers",
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $template.layers
        )
        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    foreach ($layer in $template.layers) {
        if (-not $layer.name) {
            $exception = [System.Exception]::new(
                "Each layer must have a 'name' field."
            )
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                $exception,
                "MissingLayerName",
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $layer.name
            )
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        if (-not $layer.type) {
            $exception = [System.Exception]::new(
                "Each layer must have a 'type' field."
            )
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                $exception,
                "MissingLayerType",
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $layer.type
            )
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }

    # Define the solution name
    $solutionName = $template.solutionName

    # Define layers and their types
    $layers = $template.layers

    $Log = if ($LogToFile) {
        {
            param($Level, $Message)
            Write-Log `
                -Level $Level `
                -Message $Message `
                -OutputFile "$solutionName.log"
        }
    }
    else {
        {
            param($Level, $Message)
            Write-ConsoleLog -Level $Level -Message $Message
        }
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
        dotnet `
            sln "$($solutionName).sln" `
            add "$($projectName)/$($projectName).csproj"

        # Install NuGet packages if specified
        if ($layer.packages) {
            foreach ($package in $layer.packages) {
                & $Log Info "Installing '$($package)' for '$($projectName)'"
                dotnet `
                    add "$($projectName)/$($projectName).csproj" `
                    package $package
            }
        }
    }

    # Loop through each layer to reference projects
    foreach ($layer in $layers) {
        $projectName = "$($solutionName).$($layer.name)"

        if ($layer.projectReferences) {
            foreach ($projectReference in $layer.projectReferences) {
                & $Log Info `
                    "Adding reference '$($projectName)'" + `
                    " project to '$($solutionName).$($projectReference)'"
                dotnet `
                    add $projectName `
                    reference "$($solutionName).$($projectReference)"
            }
        }
    }

    & $Log Info "Layered .NET project '$solutionName' initialized successfully!"
}
