$script:tempDir = "$PSScriptRoot\Temp"

Describe "Initialize-LayeredDotnetProject" {
    BeforeEach {
        [void](New-Item -Path $tempDir -ItemType Directory)
        Set-Location $tempDir
    }

    AfterEach {
        Set-Location (Split-Path -Parent $tempDir)
        Remove-Item $tempDir -Recurse -Force
    }

    Context "When the JSON template is invalid" {
        It "throws 'InvalidJson' when the template is not a valid JSON structure" -TestCases @(
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
                ExpectedErrorId = "InvalidJson,Initialize-LayeredDotnetProject"
            }
        ) {
            param($Template, $ExpectedErrorId)
            $guid = [System.Guid]::NewGuid().ToString()
            $templatePath = "$tempDir\$guid.template.json"
            Set-Content -Path $templatePath -Value $Template

            { Initialize-LayeredDotnetProject -TemplateJsonPath $templatePath } |
            Should -Throw -ErrorId $ExpectedErrorId
        }

        It "throws 'InvalidJsonAgainstSchemaDetailed' when required fields are missing or schema is incorrect" -TestCases @(
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
                ExpectedErrorId = "InvalidJsonAgainstSchemaDetailed,Initialize-LayeredDotnetProject"
            }
            @{
                Template        = @(
                    '{'
                    '    "solutionName": "Example"'
                    '}'
                )
                ExpectedErrorId = "InvalidJsonAgainstSchemaDetailed,Initialize-LayeredDotnetProject"
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
                ExpectedErrorId = "InvalidJsonAgainstSchemaDetailed,Initialize-LayeredDotnetProject"
            }
        ) {
            param($Template, $ExpectedErrorId)
            $guid = [System.Guid]::NewGuid().ToString()
            $templatePath = "$tempDir\$guid.template.json"
            Set-Content -Path $templatePath -Value $Template

            { Initialize-LayeredDotnetProject -TemplateJsonPath $templatePath } |
            Should -Throw -ErrorId $ExpectedErrorId
        }
    }

    Context "When the template file is missing or the output path is invalid" {
        It "throws 'FileNotFound' when the template file does not exist" -TestCases @(
            @{
                TemplatePath = "FakeTemplate.json"
            }
            @{
                TemplatePath = "FakeDirectory\FakeTemplate.json"
            }
        ) {
            param ($TemplatePath)
            { Initialize-LayeredDotnetProject -TemplateJsonPath $TemplatePath } |
            Should -Throw -ErrorId "FileNotFound,Initialize-LayeredDotnetProject"
        }

        It "throws 'FileNotFound' when the output path points to a file instead of a directory" {
            $directoryName = "DirectoryIsFile"
            $directoryPath = "$tempDir\$directoryName"

            [void](New-Item -Path $tempDir -Name $directoryName -ItemType File)

            { Initialize-LayeredDotnetProject -TemplateJsonPath "$directoryPath\Template.json" } |
            Should -Throw -ErrorId "FileNotFound,Initialize-LayeredDotnetProject"
        }
    }

    Context "When valid template provided" {
        BeforeEach {
            . "$PSScriptRoot\..\Src\Classes\CommandNotFoundException.ps1"
            . "$PSScriptRoot\..\Src\Private\WriteConsoleLog.ps1"
            . "$PSScriptRoot\..\Src\Private\WriteLog.ps1"
            . "$PSScriptRoot\..\Src\Private\AssertCliInstalled.ps1"
            . "$PSScriptRoot\..\Src\Public\Initialize-LayeredDotnetProject.ps1"

            Mock Assert-CliInstalled {}
            Mock Write-ConsoleLog {}
            Mock Write-Log {}
            Mock dotnet { return "mocked" }
            Mock Get-Date { return [datetime]"2024-01-01 00:00:00" }
        }

        It "runs dotnet CLI and logs" {
            New-LayeredDotnetTemplate

            $defaultPath = ".\layers.template.json"

            Initialize-LayeredDotnetProject -TemplateJsonPath $defaultPath

            Should -Invoke Assert-CliInstalled -Times 1 -Exactly
            Should -Invoke dotnet -Times 1
            Should -Invoke Write-ConsoleLog -Times 1
        }

        It "creates Directory.Build.props unless NoDirectoryBuildFile is specified" {
            New-LayeredDotnetTemplate

            $defaultPath = ".\layers.template.json"

            Initialize-LayeredDotnetProject -TemplateJsonPath $defaultPath

            Test-Path "Directory.Build.props" | Should -BeTrue
        }
    }
}
