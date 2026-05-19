Describe "Template Validation" {
    BeforeAll {
        $moduleRoot = (Get-Module DotPilot.ProjectScaffold).ModuleBase

        function Get-TemplatePath([string] $TemplateDir, [string]$Name) {
            Join-Path $moduleRoot "Template" $TemplateDir $Name
        }

        function Get-SchemaPath([string]$Name) {
            Join-Path $moduleRoot "Schemas" "$Name.schema.json"
        }
    }

    Context "Layered Dotnet Template" -Tag "Dotnet" {
        BeforeDiscovery {
            $script:cases = @(
                "AspNetWebApiClean.template.json"
                "WinFormsThreeLayers.template.json"
                "Default.template.json"
            )
        }

        It "Template file exists - <_>" -TestCases $cases {
            Get-TemplatePath -TemplateDir "Dotnet" $_ | Should -Exist
        }

        It "Template conforms to LayeredDotnet schema - <_>" -TestCases $cases {
            $templatePath = Get-TemplatePath -TemplateDir "Dotnet" $_
            $schemaPath = Get-SchemaPath "LayeredDotnet"

            Test-Json -Path $templatePath -SchemaFile $schemaPath | `
                Should -BeTrue
        }
    }
}
