<#
Input space
-----------
All external calls (dotnet, Write-Log, Assert-CommandExists, Assert-FileExists,
Test-Json, Get-Content, ConvertFrom-Json) are mocked so only the props-file
branch is exercised here.

Param `$TemplateJsonPath`:
    Any non-null, non-whitespace string. Drives two branches: file missing ->
    throw FileNotFoundException; file exists, JSON invalid -> throw (Test-Json
    error); file exists, JSON valid -> proceed.

Param `$NoDirectoryBuildFile`:
    [switch]. Controls whether Directory.Build.props is written.
    Absent ($false) -> Set-Content called -> file created.
    Present ($true) -> Set-Content skipped -> file NOT created.

################################################################################

Equivalence Partitioning
------------------------
1. For `$TemplateJsonPath` (file existence)
Partition   Representative         Expected
---------   --------------         --------
Missing     "<nonexistent>.json"   Throw FileNotFoundException
Exists      (temp file on disk)    Proceed past guard

2. For `$TemplateJsonPath` (JSON validity, file exists)
Partition      Representative           Expected
---------      --------------           --------
Invalid JSON   "{bad json}"             Throw (Test-Json error)
Valid JSON     <well-formed template>   Proceed to scaffold

3. For `$NoDirectoryBuildFile`
Partition   Representative          Expected
---------   --------------          --------
Absent      (omit / $false)         Directory.Build.props created
Present     -NoDirectoryBuildFile   Directory.Build.props NOT created

################################################################################

Decision table
--------------
TemplateJsonPath   NoDirectoryBuildFile   Expected
----------------   --------------------   --------
Missing            *                      Throw FileNotFoundException
Exists, invalid    *                      Throw (Test-Json)
Exists, valid      Absent                 Directory.Build.props created
Exists, valid      Present                Directory.Build.props NOT created

Note:
1.  'Missing + NoDirectoryBuildFile' and 'Exists, invalid +
    NoDirectoryBuildFile' are not tested. Both throw before the props branch
    is reached ('Missing + *' and 'Exists, invalid + *').

2.  dotnet, Write-Log, Assert-CommandExists, Assert-FileExists, Test-Json,
    Get-Content, and ConvertFrom-Json are mocked in all contexts so only
    the props-file side-effect is observable here. Their wiring is verified by
    integration tests.

################################################################################

Test map
--------
ID   Context       Input                       TDT   Assert
--   -------       -----                       ---   ------
01   FNF           <missing>.json, no switch   DT    Throw FileNotFoundException
02   InvalidJson   <bad json>, no switch       DT    Throws (terminating error)
03   Base          valid JSON, no switch       DT    Props file created
04   NoDir         valid JSON, -NoDir          DT    Props file NOT created

List of Abbreviations:
'*'   - Any value; column is irrelevant on this path
TDT   - Test Design Technique
DT    - Decision Table
FNF   - File Not Found
NoDir - NoDirectoryBuildFile switch present
Props - Directory.Build.props
#>
Describe "Initialize-LayeredDotnetProject" -Tag @(
    "Initialize-LayeredDotnetProject"
    "Initialize-LayeredDotnetProject.Unit"
    "Initialize-Layered*Project"
    "Initialize-Layered*Project.Unit"
    "Unit"
) {
    BeforeAll {
        $moduleSrc = Join-Path $PSScriptRoot ".." ".." "Src"
        $coreModuleSrc = Join-Path $PSScriptRoot ".." ".." ".." `
            "DotPilot.Core" "Src"

        . (Join-Path $coreModuleSrc "Classes" "FileNotFoundException.ps1")
        . (Join-Path $coreModuleSrc "Enums" "LogLevel.ps1")
        . (Join-Path $coreModuleSrc "Public" "Assert-CommandExists.ps1")
        . (Join-Path $coreModuleSrc "Public" "Assert-FileExists.ps1")
        . (Join-Path $moduleSrc "Public" "Initialize-LayeredDotnetProject.ps1")
        . (Join-Path $moduleSrc "Types" "DotnetTemplate.Types.ps1")

        Mock Write-Host {}
        Mock Write-Log {}
        Mock dotnet {}

        # Minimal valid template object returned by mocked ConvertFrom-Json.
        $script:emptyStrList = [System.Collections.Generic.List[string]]@()
        $script:minimalTemplate = [DotnetTemplate]@{
            WorkspaceName = "MyProject"
            Layers        = @(
                [DotnetLayer]@{
                    Name              = "Core"
                    Type              = "classlib"
                    ExtraArguments    = ""
                    Packages          = $script:emptyStrList
                    ProjectReferences = $script:emptyStrList
                }
            )
        }
    }

    Context "When TemplateJsonPath points to a missing file" {
        BeforeAll {
            $script:missingJson = Join-Path $TestDrive "missing.template.json"
            $script:caughtError = $null

            try {
                Initialize-LayeredDotnetProject `
                    -TemplateJsonPath $script:missingJson
            }
            catch {
                $script:caughtError = $_
            }

            if ($null -eq $script:caughtError) {
                throw @(
                    "Guard: Initialize-LayeredDotnetProject did not throw"
                    " - all assertions in this Context are invalid."
                ) -join ''
            }
        }

        # 01
        It "Throws FileNotFoundException" {
            $script:caughtError.Exception | Should -BeOfType (
                [FileNotFoundException]
            )
        }
    }

    Context "When the template file contains invalid JSON" {
        BeforeAll {
            $script:badJsonFile = Join-Path $TestDrive "bad.template.json"
            Set-Content -Path $script:badJsonFile -Value "{bad json}"

            # Assert-FileExists must pass so Test-Json is actually reached.
            Mock Assert-FileExists {}

            $script:caughtError = $null

            try {
                Initialize-LayeredDotnetProject `
                    -TemplateJsonPath $script:badJsonFile
            }
            catch {
                $script:caughtError = $_
            }

            if ($null -eq $script:caughtError) {
                throw @(
                    "Guard: Initialize-LayeredDotnetProject did not throw"
                    " - all assertions in this Context are invalid."
                ) -join ''
            }
        }

        # 02
        It "Throws a terminating error" {
            $script:caughtError | Should -Not -BeNullOrEmpty
        }
    }

    Context "When template is valid and NoDirectoryBuildFile is absent" {
        BeforeAll {
            $script:templateFile = Join-Path `
                $TestDrive "MyProject.template.json"
            Set-Content -Path $script:templateFile -Value "{}"

            Mock Assert-FileExists {}
            Mock Assert-CommandExists {}
            Mock Get-Content { return "{}" } -ParameterFilter {
                $Path -eq $script:templateFile
            }
            Mock Test-Json { return $true }
            Mock ConvertFrom-Json { return $script:minimalTemplate }

            $script:propsFile = Join-Path $TestDrive "Directory.Build.props"

            Push-Location $TestDrive

            Initialize-LayeredDotnetProject `
                -TemplateJsonPath $script:templateFile
        }

        AfterAll {
            Pop-Location
        }

        # 03
        It "Creates Directory.Build.props in the current directory" {
            $script:propsFile | Should -Exist

            # Sanity check - ensure the file created by Set-Content has expected
            # content.
            Get-Content $script:propsFile | Should -Contain '<Project>'
        }
    }

    Context "When NoDirectoryBuildFile switch is present" {
        BeforeAll {
            $script:templateFile = Join-Path `
                $TestDrive "MyProject.template.json"
            Set-Content -Path $script:templateFile -Value "{}"

            Mock Assert-FileExists {}
            Mock Assert-CommandExists {}
            Mock Get-Content { return "{}" }
            Mock Test-Json { return $true }
            Mock ConvertFrom-Json { return $script:minimalTemplate }

            $script:propsFile = Join-Path $TestDrive "Directory.Build.props"

            Push-Location $TestDrive

            Initialize-LayeredDotnetProject `
                -TemplateJsonPath $script:templateFile `
                -NoDirectoryBuildFile
        }

        AfterAll {
            Pop-Location
        }

        # 04
        It "Does not create Directory.Build.props" {
            $script:propsFile | Should -Not -Exist
        }
    }
}
