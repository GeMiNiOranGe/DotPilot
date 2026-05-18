BeforeAll {
    Import-Module DotPilot.ProjectScaffold -Force
}

Describe "Dotnet scaffolding" -Tag @(
    "Dotnet"
    "E2E"
) {
    BeforeAll {
        Push-Location $TestDrive

        # Step 1: Using default preset to generate template JSON file
        New-LayeredDotnetTemplate `
            -OutputPath "MyProject.template.json" `
            -WorkspaceName "MyProject"

        # Step 2
        Initialize-LayeredDotnetProject `
            -TemplateJsonPath "MyProject.template.json"
    }

    AfterAll {
        Pop-Location
    }

    Context "Template file" {
        It "should create the template JSON file" {
            "MyProject.template.json" | Should -Exist
        }

        It "should contain correct workspace name" {
            $content = Get-Content "MyProject.template.json" -Raw | `
                ConvertFrom-Json
            $content.workspaceName | Should -Be "MyProject"
        }
    }

    Context "Solution structure" {
        It "should create the solution file" {
            "MyProject.sln" | Should -Exist
        }

        It "should create Directory.Build.props" {
            "Directory.Build.props" | Should -Exist
        }

        It "should create .gitignore" {
            ".gitignore" | Should -Exist
        }
    }

    Context "Project layers" {
        It "should create MyProject.<Layer> project" -TestCases @(
            @{ Layer = "LayerOne" }
            @{ Layer = "LayerTwo" }
            @{ Layer = "LayerThree" }
        ) {
            "MyProject.$Layer/MyProject.$Layer.csproj" | Should -Exist
        }
    }

    Context "Solution integrity" {
        It "should build successfully" {
            $result = dotnet build "MyProject.sln" 2>&1
            $LASTEXITCODE | Should -Be 0 -Because ($result -join "`n")
        }
    }
}
