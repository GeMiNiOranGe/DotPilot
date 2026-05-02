$script:tempDir = Join-Path $PSScriptRoot "Temp"

Describe "Initialize-LayeredDotnetProject" -Tag @(
    "Initialize-LayeredDotnetProject"
    "Dotnet"
) {
    BeforeAll {
        $coreModuleSrc = Join-Path $PSScriptRoot ".." ".." "DotPilot.Core" "Src"
        $moduleSrc = Join-Path $PSScriptRoot ".." "Src"

        . (Join-Path $coreModuleSrc "Enums" "LogFormat.ps1")
        . (Join-Path $coreModuleSrc "Enums" "LogLevel.ps1")
        . (Join-Path $coreModuleSrc "Public" "Assert-CommandExists.ps1")
        . (Join-Path $moduleSrc "Config" "Defaults.ps1")
        . (Join-Path $moduleSrc "Private" "Invoke-ForceOutputGuard.ps1")
        . (Join-Path $moduleSrc "Public" "Initialize-LayeredDotnetProject.ps1")
        . (Join-Path $moduleSrc "Public" "New-LayeredDotnetTemplate.ps1")
    }

    BeforeEach {
        [void](New-Item -Path $tempDir -ItemType Directory)
        Set-Location $tempDir
    }

    AfterEach {
        Set-Location (Split-Path -Parent $tempDir)
        Remove-Item $tempDir -Recurse -Force
    }

    Context "When the JSON template is invalid" {
        It "Throws '<ExpectedErrorId>'" -TestCases @(
            @{
                Template        = @(
                    '"workspaceName": "Example",'
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
                    '    "workspaceName": "Example"'
                    '}'
                )
                ExpectedErrorId = "InvalidJsonAgainstSchemaDetailed"
            }
            @{
                Template        = @(
                    '{'
                    '    "workspaceName": "Example",'
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
            $templatePath = Join-Path $tempDir "$guid.template.json"
            Set-Content -Path $templatePath -Value $Template

            { Initialize-LayeredDotnetProject -TemplateJsonPath $templatePath } |
            Should -Throw -ErrorId (
                "$ExpectedErrorId,Initialize-LayeredDotnetProject"
            )
        }
    }

    Context "When the template file path is invalid" {
        It "Throws 'FileNotFound' when the template file does not exist" {
            $path = Join-Path "FakeDirectory" "FakeTemplate.json"
            { Initialize-LayeredDotnetProject -TemplateJsonPath $path } |
            Should -Throw -ErrorId "FileNotFound,Initialize-LayeredDotnetProject"
        }
    }

    Context "When valid template provided" {
        BeforeAll {
            Mock Assert-CommandExists {}
            Mock dotnet { return "mocked" }

            $global:DotPilot.Log.FileLogging = $true
            $global:DotPilot.Log.FileFormat = [LogFormat]::Log
        }

        It "Runs dotnet CLI and logs" {
            New-LayeredDotnetTemplate

            Initialize-LayeredDotnetProject `
                -TemplateJsonPath $DefaultTemplateOutputPath

            Should -Invoke Assert-CommandExists -Times 1 -Exactly
            Should -Invoke dotnet -Times 1
        }

        It "Creates Directory.Build.props unless NoDirectoryBuildFile is set" {
            New-LayeredDotnetTemplate

            Initialize-LayeredDotnetProject `
                -TemplateJsonPath $DefaultTemplateOutputPath

            Test-Path "Directory.Build.props" | Should -BeTrue
        }
    }
}
