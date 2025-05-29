$script:srcPath = "$PSScriptRoot\..\Src"

Describe "Template Validation" {
    Context "Layered Dotnet Template" {
        It "Should be valid according to LayeredDotnet schema - <ArchitectureTemplate>" -TestCases @(
            @{
                ArchitectureTemplate = "CleanArchitecture.template.json"
            }
            @{
                ArchitectureTemplate = "DefaultLayers.template.json"
            }
        ) {
            param($ArchitectureTemplate)

            $architecturePath = "$srcPath\Template\Dotnet\$ArchitectureTemplate"

            $isValidPath = Test-Path -Path $architecturePath
            $isValidPath | Should -BeTrue -Because (
                "template file '$ArchitectureTemplate' must exist"
            )

            $isValidSchema = Test-Json `
                -Path $architecturePath `
                -SchemaFile "$srcPath\Schemas\LayeredDotnet.schema.json"
            $isValidSchema | Should -BeTrue -Because (
                "template '$ArchitectureTemplate' must conform to LayeredDotnet schema"
            )
        }
    }
}
