<#
Input space
-----------
Param `$TemplateJsonPath`:
    Any non-null, non-whitespace string. Drives two branches: file exists AND
    valid JSON -> proceed; file missing -> throw FileNotFoundException; file
    exists but invalid JSON -> throw Test-Json error.

Param `$NoDirectoryBuildFile`:
    [switch]. Controls whether Directory.Build.props is created.
    Absent (default $false) -> file is created.
    Present ($true)         -> file is NOT created.

External dependencies that affect observable behavior:
    dotnet CLI - must be present (Assert-CommandExists guard); drives all
    filesystem output (sln, project dirs, .csproj). Mocked to avoid real dotnet
    invocations.

    Write-Log - called for progress output. Mocked to suppress console noise;
    not asserted (pass-through behavior).

    Write-Host - called transitively through Write-Log -> Write-LogConsole.
    Mocked at Describe level to silence output.

    Assert-CommandExists - real dependency; dotnet is mocked so the guard passes
    without the real CLI being present.

    Assert-FileExists - real dependency; TemplateJsonPath must point to
    a real file in tests.

    Test-Json - real dependency; validates the JSON against the schema.

    ConvertFrom-Json / Get-Content - real built-ins; not mocked.

    Set-Content - real built-in; writes Directory.Build.props.

Template data (JSON content):
    workspaceName:
        string; becomes the solution name and project prefix.

    layers:
        array of layer objects; each has name, type, extraArguments, packages,
        projectReferences.

    These are data-domain concerns tested indirectly through the
    observable side-effects (dotnet calls, file creation).

################################################################################

Equivalence Partitioning
------------------------
1. For `$TemplateJsonPath` (file existence)
Partition   Representative         Expected
---------   --------------         --------
Missing     "<nonexistent>.json"   Throw FileNotFoundException
Exists      (temp file on disk)    Proceed past guard

2. For `$TemplateJsonPath` (JSON validity, only when file exists)
Partition      Representative           Expected
---------      --------------           --------
Invalid JSON   "bad json"               Throw (Test-Json error)
Valid JSON     <well-formed template>   Proceed to scaffold

3. For `$NoDirectoryBuildFile`
Partition   Representative                  Expected
---------   --------------                  --------
Absent      (omit / $false)                 Directory.Build.props created
Present     -NoDirectoryBuildFile ($true)   Not created

4. For layers[].extraArguments (only when JSON is valid)
Partition   Representative         Expected
---------   --------------         --------
Empty       ""                     dotnet new called without extra arg
Non-empty   "--framework net9.0"   extra arg appended to dotnet new

5. For layers[].packages (only when JSON is valid)
Partition   Representative        Expected
---------   --------------        --------
Empty       []                    dotnet add package NOT called for layer
Non-empty   ["Newtonsoft.Json"]   dotnet add package called once per pkg

6. For layers[].projectReferences (only when JSON is valid)
Partition   Representative   Expected
---------   --------------   --------
Empty       []               dotnet add reference NOT called for layer
Non-empty   ["Core"]         dotnet add reference called once per ref

################################################################################

Decision table
--------------
Template   NoDir     Extra      Packages   ProjRefs   Expected
JsonPath             Args
--------   -----     -----      --------   --------   --------
Missing    Any       Any        Any        Any        Throw
                                                      FileNotFoundException
Exists,    Any       Any        Any        Any        Throw (Test-Json)
invalid
Exists,    Absent    Empty      Empty      Empty      props created; sln+proj
valid                                                 created; no pkg/ref calls
Exists,    Present   Empty      Empty      Empty      props NOT created;
valid                                                 sln+proj created
Exists,    Absent    NonEmpty   Empty      Empty      dotnet new called with
valid                                                 extra arg
Exists,    Absent    Empty      NonEmpty   Empty      dotnet add package called
valid
Exists,    Absent    Empty      Empty      NonEmpty   dotnet add reference
valid                                                 called

Note:
1.  'Missing + NoDirectoryBuildFile/ExtraArgs/Packages/ProjRefs' combinations
    are not tested. FileNotFoundException is thrown before any of those
    branches are reached ('Missing + Any').

2.  'Exists, invalid + NoDirectoryBuildFile' is not tested. The Test-Json
    error is thrown before the $NoDirectoryBuildFile branch ('Exists, invalid +
    Any').

3.  dotnet new call without extra args is verified on the base valid-JSON row
    ('Exists, valid + Absent + Empty + Empty + Empty'). The extra-args row only
    asserts the appended argument, not the full call, to avoid redundancy.

4.  The $NoDirectoryBuildFile row ('Exists, valid + Present + ...') focuses
    only on the absence of Directory.Build.props; all other dotnet assertions
    are already covered by the base valid-JSON row.

5.  Packages and ProjectReferences are tested on separate rows each ('Exists,
    valid + Absent + Empty + Non-empty + Empty' and 'Exists, valid + Absent +
    Empty + Empty + Non-empty'). Combining them into one row would not reveal
    additional behavior.

################################################################################

Test map
--------
ID   Context       Input                       TDT   Assert
--   -------       -----                       ---   ------
01   FNF           <missing>.json, no switch   DT    Throw FileNotFoundException
02   InvalidJson   <bad json>, no switch       DT    Throws (terminating error)
03   Base          valid template, no switch   DT    Props created
04   Base          ^                           ^     dotnet new gitignore called
05   Base          ^                           ^     dotnet new sln called
06   Base          ^                           ^     dotnet new <type> called
07   Base          ^                           ^     dotnet sln add called
08   NoDir         valid template, -NoDir      DT    Props NOT created
09   ExtraArgs     layer.ExtraArgs=            DT    dotnet new w/ extra arg
                   "--framework net9.0"
10   Packages      layer.Packages=             DT    dotnet add package called
                   ["Newtonsoft.Json"]
11   ProjRefs      layer.ProjectReferences=    DT    dotnet add ref called
                   ["Core"]

List of Abbreviations:
'^'   - Same input/TDT as previous row
TDT   - Test Design Technique
DT    - Decision Table
FNF   - File Not Found
NoDir - NoDirectoryBuildFile switch present
SUT   - System Under Test (Initialize-LayeredDotnetProject)
Props - Directory.Build.props
#>
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
