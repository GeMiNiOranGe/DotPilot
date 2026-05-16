$script:srcPath = (Get-Module DotPilot.ProjectScaffold).ModuleBase

Describe "Template Validation" {
    Context "Layered Dotnet Template" -Tag "Dotnet" {
        It "Should be valid according to LayeredDotnet schema - <RawTemplate>" -TestCases @(
            @{
                RawTemplate = "AspNetWebApiClean.template.json"
            }
            @{
                RawTemplate = "WinFormsThreeLayers.template.json"
            }
            @{
                RawTemplate = "Default.template.json"
            }
        ) {
            param($RawTemplate)

            $architecturePath = Join-Path $srcPath "Template" "Dotnet" `
                $RawTemplate

            $isValidPath = Test-Path -Path $architecturePath
            $isValidPath | Should -BeTrue -Because (
                "template file '$RawTemplate' must exist"
            )

            $schemaFilePath = Join-Path $srcPath "Schemas" `
                "LayeredDotnet.schema.json"
            $isValidSchema = Test-Json `
                -Path $architecturePath `
                -SchemaFile $schemaFilePath
            $isValidSchema | Should -BeTrue -Because (
                "template '$RawTemplate' must conform to LayeredDotnet schema"
            )
        }
    }
}
