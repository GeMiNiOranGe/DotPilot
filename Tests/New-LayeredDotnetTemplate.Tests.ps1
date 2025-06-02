Describe "New-LayeredDotnetTemplate" -Tag "Dotnet" {
    BeforeAll {
        . "$PSScriptRoot\..\Src\Private\WriteConsoleLog.ps1"
        . "$PSScriptRoot\..\Src\Public\New-LayeredDotnetTemplate.ps1"

        Mock Write-ConsoleLog {}
    }

    Context "When using a valid '-OutputPath' option" {
        It "Creates the default template file in current directory" {
            $defaultPath = ".\layers.template.json"

            New-LayeredDotnetTemplate

            Test-Path $defaultPath | Should -BeTrue
            Get-Content $defaultPath -Raw | Should -Match '"Example"'

            Remove-Item $defaultPath
        }

        It "Creates the template file at the specified output path" {
            $outPath = "$env:TEMP\Template.json"

            New-LayeredDotnetTemplate -OutputPath $outPath

            Test-Path $outPath | Should -BeTrue
            Get-Content $outPath -Raw | Should -Match '"Example"'

            Remove-Item $outPath
        }
    }

    Context "When using an invalid '-OutputPath' option" {
        It (
            "Throws a DirectoryNotFound error if the output directory does " +
            "not exist"
        ) {
            $invalidPath = "$env:TEMP\DirectoryNotExist\Template.json"

            { New-LayeredDotnetTemplate -OutputPath $invalidPath } |
            Should -Throw -ErrorId "DirectoryNotFound,New-LayeredDotnetTemplate"
        }

        It (
            "Throws an error when the output path points to a file instead " +
            "of a directory"
        ) {
            $directoryName = "DirectoryIsFile"
            $directoryPath = "$env:TEMP\$directoryName"

            # Create a file with the same name as the intended directory
            [void](New-Item -Path $env:TEMP -Name $directoryName -ItemType File)

            { New-LayeredDotnetTemplate -OutputPath "$directoryPath\Template.json" } |
            Should -Throw -ErrorId (
                "GetContentWriterDirectoryNotFoundError,New-LayeredDotnetTemplate"
            )

            Remove-Item $directoryPath
        }
    }

    Context "When replacing the '{{solutionName}}' placeholder" {
        It (
            "Replaces '{{solutionName}}' with the default value 'Example' " +
            "for different architectures (Architecture: " +
            "<TemplateArguments.Architecture>)"
        ) -TestCases @(
            @{ TemplateArguments = @{ Architecture = "Clean" } }
            @{ TemplateArguments = @{ Architecture = "WinFormsThreeLayers" } }
            @{ TemplateArguments = @{} }
        ) {
            param ($TemplateArguments)

            $defaultPath = ".\layers.template.json"

            New-LayeredDotnetTemplate @TemplateArguments

            $content = Get-Content $defaultPath -Raw
            $content | Should -Match '"Example"'

            Remove-Item $defaultPath
        }
    }

    <#
    Context "When passing placeholder value" {
        # TODO: Check not to pass `-SolutionName` is `"{{solutionName}}"` which
        # means not allowed to pass the correct placeholder in the template
        It (
            "Ensures '{{solutionName}}' is not replaced even if passed " +
            "explicitly as a value"
        ) {
            $defaultPath = ".\layers.template.json"
            New-LayeredDotnetTemplate -SolutionName "{{solutionName}}"
            $content = Get-Content $defaultPath -Raw
            $content | Should -Not -Match '"{{solutionName}}"'
            Remove-Item $defaultPath
        }
    }
     #>
}
