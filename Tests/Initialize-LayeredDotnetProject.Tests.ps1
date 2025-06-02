$script:tempDir = "$PSScriptRoot\Temp"

Describe "Initialize-LayeredDotnetProject" -Tag "Dotnet" {
    BeforeEach {
        [void](New-Item -Path $tempDir -ItemType Directory)
        Set-Location $tempDir
    }

    AfterEach {
        Set-Location (Split-Path -Parent $tempDir)
        Remove-Item $tempDir -Recurse -Force
    }

    Context "When the JSON template is invalid" {
        It (
            "Throws '<ExpectedErrorId>' when required fields are missing or " +
            "schema is incorrect"
        ) -TestCases @(
            @{
                Template        = @(
                    '"solutionName": "Example",'
                    '"layers": ['
                    '    {'
                    '        "name": "Core",'
                    '        "type": "classlib",'
                    '        "extraArguments": "",'
                    '        "packages": [],'
                    '        "projectReferences": []'
                    '    }'
                    ']'
                )
                ExpectedErrorId = "InvalidJson"
            }
            @{
                Template        = @(
                    '{'
                    '    "layers": ['
                    '        {'
                    '            "name": "Core",'
                    '            "type": "classlib",'
                    '            "extraArguments": "",'
                    '            "packages": [],'
                    '            "projectReferences": []'
                    '        }'
                    '    ]'
                    '}'
                )
                ExpectedErrorId = "InvalidJsonAgainstSchemaDetailed"
            }
            @{
                Template        = @(
                    '{'
                    '    "solutionName": "Example"'
                    '}'
                )
                ExpectedErrorId = "InvalidJsonAgainstSchemaDetailed"
            }
            @{
                Template        = @(
                    '{'
                    '    "solutionName": "Example",'
                    '    "layers": ['
                    '        {'
                    '            "type": "classlib",'
                    '            "extraArguments": "",'
                    '            "packages": [],'
                    '            "projectReferences": []'
                    '        }'
                    '    ]'
                    '}'
                )
                ExpectedErrorId = "InvalidJsonAgainstSchemaDetailed"
            }
        ) {
            param($Template, $ExpectedErrorId)
            $guid = [System.Guid]::NewGuid().ToString()
            $templatePath = "$tempDir\$guid.template.json"
            Set-Content -Path $templatePath -Value $Template

            { Initialize-LayeredDotnetProject -TemplateJsonPath $templatePath } |
            Should -Throw -ErrorId (
                "$ExpectedErrorId,Initialize-LayeredDotnetProject"
            )
        }
    }

    Context "When the template file path is invalid" {
        It "Throws 'FileNotFound' when the template file does not exist" {
            $path = "FakeDirectory\FakeTemplate.json"
            { Initialize-LayeredDotnetProject -TemplateJsonPath $path } |
            Should -Throw -ErrorId "FileNotFound,Initialize-LayeredDotnetProject"
        }
    }

    Context "When valid template provided" {
        BeforeAll {
            . "$PSScriptRoot\..\Src\Classes\CommandNotFoundException.ps1"
            . "$PSScriptRoot\..\Src\Private\WriteConsoleLog.ps1"
            . "$PSScriptRoot\..\Src\Private\WriteLog.ps1"
            . "$PSScriptRoot\..\Src\Private\AssertCliInstalled.ps1"
            . "$PSScriptRoot\..\Src\Public\Initialize-LayeredDotnetProject.ps1"
            . "$PSScriptRoot\..\Src\Public\New-LayeredDotnetTemplate.ps1"

            Mock Assert-CliInstalled {}
            Mock Write-ConsoleLog {}
            Mock Write-Log {}
            Mock dotnet { return "mocked" }
        }

        It "Runs dotnet CLI and logs" {
            New-LayeredDotnetTemplate

            $defaultPath = ".\layers.template.json"

            Initialize-LayeredDotnetProject -TemplateJsonPath $defaultPath

            Should -Invoke Assert-CliInstalled -Times 1 -Exactly
            Should -Invoke dotnet -Times 1
            Should -Invoke Write-ConsoleLog -Times 1
        }

        It (
            "Creates Directory.Build.props unless NoDirectoryBuildFile is " +
            "specified"
        ) {
            New-LayeredDotnetTemplate

            $defaultPath = ".\layers.template.json"

            Initialize-LayeredDotnetProject -TemplateJsonPath $defaultPath

            Test-Path "Directory.Build.props" | Should -BeTrue
        }
    }
}
