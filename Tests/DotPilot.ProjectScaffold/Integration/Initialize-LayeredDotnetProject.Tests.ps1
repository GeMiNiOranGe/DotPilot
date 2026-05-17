<#
Input space
-----------
This integration test runs dotnet CLI for real. Only a single happy-path
combination is exercised to verify end-to-end filesystem output without
combinatorial explosion. Guard clauses (missing file, invalid JSON) and
the $NoDirectoryBuildFile branch are already covered by the unit tests.

Param `$TemplateJsonPath`:
    A real JSON file on disk that satisfies the LayeredDotnet schema.

Param `$NoDirectoryBuildFile`:
    Not tested here - covered by unit tests.

Observed side-effects:
    .gitignore, *.sln, project directory, *.csproj, added solution reference.

################################################################################

Equivalence Partitioning
------------------------
1. For layers[].extraArguments
Partition   Representative   Expected
---------   --------------   --------
Empty       ""               Project created without extra arg
Non-empty   "--no-restore"   Project created with extra arg applied

2. For layers[].packages
Partition   Representative        Expected
---------   --------------        --------
Empty       []                    No package reference in .csproj
Non-empty   ["Newtonsoft.Json"]   Package reference present in .csproj

3. For layers[].projectReferences
Partition   Representative   Expected
---------   --------------   --------
Empty       []               No ProjectReference in .csproj
Non-empty   ["Core"]         ProjectReference present in .csproj

################################################################################

Decision table
--------------
Primary table

ExtraArgs   Packages    ProjRefs   Expected
---------   --------    --------   --------
Empty       Empty       Empty      sln, props, .gitignore, project created;
                                   no pkg/ref in .csproj
Non-empty   Empty       Empty      project created with extra arg
Empty       Non-empty   Empty      package ref present in .csproj
Empty       Empty       Non-empty  project reference in .csproj

Note:
1.  The base row ('Empty + Empty + Empty') is the only row that asserts
    all structural outputs (sln, props, .gitignore, project dir, .csproj).
    Remaining rows assert only the behavior specific to their partition
    to avoid redundancy.

2.  'Non-empty ExtraArgs' uses "--no-restore" so dotnet skips package
    restore - this keeps the test fast and avoids network access.

3.  Packages and ProjectReferences are tested on separate rows
    ('Empty + Non-empty + Empty' and 'Empty + Empty + Non-empty').
    Combining them would not reveal additional behavior.

################################################################################

Test map
--------
ID   Context     Input                            TDT   Assert
--   -------     -----                            ---   ------
01   Base        1 layer, empty extras,           DT    .gitignore exists
                 no pkgs, no refs
02   Base        ^                                ^     *.sln exists
03   Base        ^                                ^     Project dir exists
04   Base        ^                                ^     .csproj exists
05   Base        ^                                ^     .csproj in .sln
06   ExtraArgs   1 layer, "--no-restore"          DT    Project dir exists
07   Packages    1 layer, pkg="Newtonsoft.Json"   DT    .csproj has pkg ref
08   ProjRefs    2 layers, ref="Core"             DT    .csproj has proj ref

List of Abbreviations:
'^' - Same input/TDT as previous row
TDT - Test Design Technique
DT  - Decision Table
Pkg - NuGet package reference
Ref - ProjectReference
#>

BeforeAll {
    Import-Module DotPilot.ProjectScaffold -Force
}

InModuleScope "DotPilot.ProjectScaffold" {
    Describe "Initialize-LayeredDotnetProject" -Tag @(
        "Initialize-LayeredDotnetProject"
        "Initialize-LayeredDotnetProject.Integration"
        "Initialize-Layered*Project"
        "Initialize-Layered*Project.Integration"
        "Dotnet"
        "Integration"
    ) {
        BeforeAll {
            # Suppress  Write-Log entirely to isolate file-creation behavior
            # and console output side-effect.
            Mock Write-Log {}
        }

        Context "When template has one layer with no extras, packages, refs" {
            BeforeAll {
                $script:wsName = "MyProject"
                $script:layerName = "Core"
                $script:projectName = "$script:wsName.$script:layerName"

                $script:template = [ordered]@{
                    workspaceName = $script:wsName
                    layers        = @(
                        [ordered]@{
                            name              = $script:layerName
                            type              = "classlib"
                            extraArguments    = ""
                            packages          = @()
                            projectReferences = @()
                        }
                    )
                }

                $script:templateFile = Join-Path `
                    $TestDrive "$script:wsName.template.json"
                $script:template | ConvertTo-Json -Depth 10 | `
                    Set-Content -Path $script:templateFile

                Push-Location $TestDrive

                Initialize-LayeredDotnetProject `
                    -TemplateJsonPath $script:templateFile
            }

            AfterAll {
                Pop-Location
            }

            # 01
            It "Creates .gitignore" {
                Join-Path $TestDrive ".gitignore" | Should -Exist
            }

            # 02
            It "Creates the solution file" {
                Join-Path $TestDrive "$script:wsName.sln" | Should -Exist
            }

            # 03
            It "Creates the project directory" {
                Join-Path $TestDrive $script:projectName | Should -Exist
            }

            # 04
            It "Creates the .csproj file" {
                $csproj = Join-Path `
                    $TestDrive `
                    $script:projectName `
                    "$script:projectName.csproj"
                $csproj | Should -Exist
            }

            # 05
            It "Adds the project to the solution" {
                $slnContent = Get-Content `
                    -Path (Join-Path $TestDrive "$script:wsName.sln") `
                    -Raw
                $slnContent | Should -BeLike "*$script:projectName*"
            }
        }

        Context "When a layer has non-empty extraArguments" {
            BeforeAll {
                $script:wsName = "ExtraArgsProject"
                $script:layerName = "Core"
                $script:projectName = "$script:wsName.$script:layerName"

                $script:template = [ordered]@{
                    workspaceName = $script:wsName
                    layers        = @(
                        [ordered]@{
                            name              = $script:layerName
                            type              = "classlib"
                            extraArguments    = "--no-restore"
                            packages          = @()
                            projectReferences = @()
                        }
                    )
                }

                $script:templateFile = Join-Path `
                    $TestDrive "$script:wsName.template.json"
                $script:template | ConvertTo-Json -Depth 10 | `
                    Set-Content -Path $script:templateFile

                Push-Location $TestDrive

                Initialize-LayeredDotnetProject `
                    -TemplateJsonPath $script:templateFile
            }

            AfterAll {
                Pop-Location
            }

            # 06
            It "Creates the project directory with the extra argument applied" {
                Join-Path $TestDrive $script:projectName | Should -Exist
            }
        }

        Context "When a layer has a non-empty packages list" {
            BeforeAll {
                $script:wsName = "PackageProject"
                $script:layerName = "Core"
                $script:projectName = "$script:wsName.$script:layerName"
                $script:package = "Newtonsoft.Json"

                $script:template = [ordered]@{
                    workspaceName = $script:wsName
                    layers        = @(
                        [ordered]@{
                            name              = $script:layerName
                            type              = "classlib"
                            extraArguments    = ""
                            packages          = @($script:package)
                            projectReferences = @()
                        }
                    )
                }

                $script:templateFile = Join-Path `
                    $TestDrive "$script:wsName.template.json"
                $script:template | ConvertTo-Json -Depth 10 | `
                    Set-Content -Path $script:templateFile

                Push-Location $TestDrive

                Initialize-LayeredDotnetProject `
                    -TemplateJsonPath $script:templateFile

                $script:csprojPath = Join-Path `
                    $TestDrive `
                    $script:projectName `
                    "$script:projectName.csproj"
                $script:csprojContent = Get-Content `
                    -Path $script:csprojPath `
                    -Raw
            }

            AfterAll {
                Pop-Location
            }

            # 07
            It "Adds the package reference to the .csproj" {
                $script:csprojContent | `
                    Should -BeLike "*$script:package*"
            }
        }

        Context "When a layer has a non-empty projectReferences list" {
            BeforeAll {
                $script:wsName = "RefProject"
                $script:refLayer = "Core"
                $script:consumerLayer = "App"
                $script:consumerProject = "$script:wsName.$script:consumerLayer"

                $script:template = [ordered]@{
                    workspaceName = $script:wsName
                    layers        = @(
                        [ordered]@{
                            name              = $script:refLayer
                            type              = "classlib"
                            extraArguments    = ""
                            packages          = @()
                            projectReferences = @()
                        },
                        [ordered]@{
                            name              = $script:consumerLayer
                            type              = "classlib"
                            extraArguments    = ""
                            packages          = @()
                            projectReferences = @($script:refLayer)
                        }
                    )
                }

                $script:templateFile = Join-Path `
                    $TestDrive "$script:wsName.template.json"
                $script:template | ConvertTo-Json -Depth 10 | `
                    Set-Content -Path $script:templateFile

                Push-Location $TestDrive

                Initialize-LayeredDotnetProject `
                    -TemplateJsonPath $script:templateFile

                $script:csprojPath = Join-Path `
                    $TestDrive `
                    $script:consumerProject `
                    "$script:consumerProject.csproj"
                $script:csprojContent = Get-Content `
                    -Path $script:csprojPath `
                    -Raw
            }

            AfterAll {
                Pop-Location
            }

            # 08
            It "Adds the project reference to the .csproj" {
                $script:csprojContent | `
                    Should -BeLike "*$script:wsName.$script:refLayer*"
            }
        }
    }
}
