. $PSScriptRoot\Utilities.ps1

# Define the solution name
$solutionName = "Example"

# Define layers and their types
$layers = @(
    @{
        name = "Core";
        type = "classlib"
    },
    @{
        name     = "UseCases";
        type     = "classlib";
        packages = @(
            "AutoMapper"
        );
        projects = @(
            "Core"
        )
    },
    @{
        name     = "Infrastructure";
        type     = "classlib";
        packages = @(
            "Microsoft.EntityFrameworkCore",
            "Microsoft.EntityFrameworkCore.SqlServer"
        );
        projects = @(
            "Core"
        )
    },
    @{
        name           = "WebApi";
        type           = "webapi";
        extraArguments = "--use-controllers";
        packages       = @(
            "NSwag.AspNetCore",
            "Scalar.AspNetCore"
        );
        projects       = @(
            "Infrastructure",
            "UseCases"
        )
    }
)

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
Write-ConsoleLog info "Creating gitignore"
dotnet new gitignore

# Create the Solution
Write-ConsoleLog info "Creating solution '$($solutionName)'"
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

    Write-ConsoleLog info "Creating '$($projectName)' project"
    dotnet @arguments

    Write-ConsoleLog info "Adding '$($projectName)' project to '$($solutionName).sln'"
    dotnet sln "$($solutionName).sln" add "$($projectName)/$($projectName).csproj"

    # Install NuGet packages if specified
    if ($layer.packages) {
        foreach ($package in $layer.packages) {
            Write-ConsoleLog info "Installing '$($package)' for '$($projectName)'"
            dotnet add "$($projectName)/$($projectName).csproj" package $package
        }
    }
}

# Loop through each layer to reference projects
foreach ($layer in $layers) {
    $projectName = "$($solutionName).$($layer.name)"

    if ($layer.projects) {
        foreach ($project in $layer.projects) {
            Write-ConsoleLog info "Adding reference '$($projectName)' project to '$($solutionName).$($project)'"
            dotnet add $projectName reference "$($solutionName).$($project)"
        }
    }
}

Write-ConsoleLog info "Clean Architecture project setup completed!"
