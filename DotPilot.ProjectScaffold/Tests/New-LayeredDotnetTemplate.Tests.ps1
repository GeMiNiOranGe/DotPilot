<#
Input space
-----------
Param `$OutputPath`:
    Any string. Optional. When absent, defaults to $DefaultTemplateOutputPath
    (".\Template.json"). Drives whether a caller-supplied path or the default
    path is used. Forwarded to Invoke-ForceOutputGuard and then Set-Content.

Param `$Force`:
    [switch]. Forwarded verbatim to Invoke-ForceOutputGuard. Controls whether
    missing parent directories are created and whether an existing file is
    overwritten. Behavior of the guard itself is covered by
    Invoke-ForceOutputGuard's own tests; here only the end-to-end effect
    (file created vs error thrown) is tested.

Param `$Preset`:
    [ValidateSet] string. Controls which raw template file is loaded.
    Three branches: "AspNetWebApiClean", "WinFormsThreeLayers", default
    (omitted or any other value accepted by the parameter).

Param `$SolutionName`:
    [ValidateNotNullOrWhiteSpace] string. Default "Example". Substituted into
    the template content via -replace "{{solutionName}}". Does not affect
    control flow, only the written content.

################################################################################

Equivalence Partitioning
------------------------
1. For `$OutputPath`
Partition   Representative   Expected
---------   --------------   --------
Absent      (omit)           Default path ".\Template.json" used
Present     ".\Out.json"     Supplied path used

2. For `$Force`
Partition   Representative   Expected
---------   --------------   --------
Absent      (omit)           Guard runs; existing file causes throw
Present     -Force           Guard skipped; existing file overwritten

3. For `$Preset`
Partition             Representative          Expected
---------             --------------          --------
Absent (default)      (omit)                  Default.template.json loaded
AspNetWebApiClean     "AspNetWebApiClean"     AspNetWebApiClean.template.json
WinFormsThreeLayers   "WinFormsThreeLayers"   WinFormsThreeLayers.template.json

4. For `$SolutionName`
Partition   Representative   Expected
---------   --------------   --------
Default     (omit)           "Example" substituted in output
Supplied    "MyProject"      "MyProject" substituted in output

################################################################################

Decision table
--------------
OutputPath   Force    Preset          SolutionName   Expected
----------   -----    ------          ------------   --------
Absent       Absent   Absent          Default        File at default path;
                                                     content has "Example"
Present      Absent   Absent          Supplied       File at supplied path;
                                                     content has supplied name
Absent       Absent   AspNetWebApi    Default        AspNetWebApiClean template
                      Clean                          loaded
Absent       Absent   WinFormsThree   Default        WinFormsThreeLayers
                      Layers                         template loaded
Present      Present  Absent          Default        File written even when
                                                     file already exists

Note:
1.  $SolutionName only affects file content, not control flow. Full substitution
    assertions are done on the first two representative combinations. Preset
    rows assert only which template was written, not re-verify solutionName
    substitution ('OutputPath Absent + Force Absent + AspNetWebApiClean' and
    'OutputPath Absent + Force Absent + WinFormsThreeLayers').

2.  $Force is only meaningful when the target file already exists or
    the parent directory is missing. The overwrite behavior is tested once on a
    representative combination where a pre-existing file is present
    ('OutputPath Present + Force Present + Absent + Default').

3.  $OutputPath Absent vs Present is covered on the first two rows. It is not
    re-tested for every Preset combination to avoid combinatorial explosion;
    the path-resolution logic is independent of Preset ('OutputPath Absent +
    Force Absent + AspNetWebApiClean' and 'OutputPath Absent + Force Absent +
    WinFormsThreeLayers').

4.  The two Preset rows ('OutputPath Absent + Force Absent + AspNetWebApiClean'
    and 'OutputPath Absent + Force Absent + WinFormsThreeLayers') share an
    identical test structure - same setup, same assertion, only the Preset value
    and its corresponding template filename differ. They are collapsed into a
    single parameterised Context with -TestCases rather than duplicated
    as separate Contexts.

################################################################################

Test map
--------
ID   Context   Input                      TDT   Assert
--   -------   -----                      ---   ------
01   OP Abs,   no OutputPath,             DT    File exists at default path
     F Abs,    no Force,
     P Def,    no Preset,
     SN Def    no SolutionName
02   ^         ^                          ^     Content contains "Example"
03   OP Pre,   OutputPath=".\Out.json",   DT    File exists at supplied path
     F Abs,    no Force, no Preset,
     P Def,    SolutionName="MyProject"
     SN Sup
04   ^         ^                          ^     Content contains "MyProject"
05   OP Abs,   no OutputPath,             DT,   Content matches template for
     F Abs,    no Force,                  TC    each Preset value
     P <P>,    Preset=<AW|WF>,
     SN Def    no SolutionName
06   OP Pre,   OutputPath=".\Out.json",   DT    File exists
     F Pre,    -Force, no Preset,
     P Def,    no SolutionName
     SN Def

List of Abbreviations:
'^' - Same context/input/technique as previous row
TDT - Test Design Technique
DT  - Decision Table
TC  - TestCases (parameterised It block)
OP  - OutputPath
F   - Force
P   - Preset
SN  - SolutionName
Abs - Absent (omitted / default)
Pre - Present (explicit value supplied)
Def - Default value used
Sup - Supplied (explicit non-default value)
AW  - AspNetWebApiClean
WF  - WinFormsThreeLayers
#>
Describe "New-LayeredDotnetTemplate" -Tag @(
    "New-LayeredDotnetTemplate"
    "New-*"
    "Integration"
) {
    BeforeAll {
        $coreModule = "$PSScriptRoot\..\..\DotPilot.Core"

        . "$coreModule\Src\Public\Assert-ParentDirectoryExists.ps1"
        . "$coreModule\Src\Public\Assert-FileNotExists.ps1"
        . "$coreModule\Src\Enums\LogLevel.ps1"
        . "$PSScriptRoot\..\Src\Config\Defaults.ps1"
        . "$PSScriptRoot\..\Src\Private\Invoke-ForceOutputGuard.ps1"
        . "$PSScriptRoot\..\Src\Public\New-LayeredDotnetTemplate.ps1"

        # Suppress console output side-effect from Write-Log -> Write-Host.
        Mock Write-Host {}
        # Suppress Write-Log entirely to isolate file-creation behavior.
        Mock Write-Log {}

        $script:templateDir = "$PSScriptRoot\..\Src\Template\Dotnet"
    }

    Context "When OutputPath is absent and Preset is default" {
        BeforeAll {
            Push-Location $TestDrive

            New-LayeredDotnetTemplate
        }

        AfterAll {
            Pop-Location
        }

        # 01
        It "Creates the file at the default output path" {
            $script:defaultFile = `
                Join-Path $TestDrive $script:DefaultTemplateOutputPath
            $script:defaultFile | Should -Exist
        }

        # 02
        It "File content contains the default solution name 'Example'" {
            $content = Get-Content `
                -Path (Join-Path $TestDrive $script:DefaultTemplateOutputPath) `
                -Raw
            $content | Should -BeLike "*Example*"
        }
    }

    Context "When OutputPath is present and SolutionName is supplied" {
        BeforeAll {
            $script:outputFile = Join-Path $TestDrive "Out.json"

            New-LayeredDotnetTemplate `
                -OutputPath $script:outputFile `
                -SolutionName "MyProject"
        }

        # 03
        It "Creates the file at the supplied output path" {
            $script:outputFile | Should -Exist
        }

        # 04
        It "File content contains the supplied solution name 'MyProject'" {
            $content = Get-Content -Path $script:outputFile -Raw
            $content | Should -BeLike "*MyProject*"
        }
    }

    Context "When Preset is specified" {
        BeforeEach {
            Push-Location $TestDrive
        }

        AfterEach {
            # Remove the output file so the next TestCase starts clean.
            # Without this, the second case hits FileAlreadyExistsException
            # because Invoke-ForceOutputGuard sees the file left by the first.
            $outputFile = Join-Path $TestDrive $script:DefaultTemplateOutputPath
            if (Test-Path $outputFile) {
                Remove-Item -Path $outputFile -Force
            }

            Pop-Location
        }

        # 05
        It "File content matches the <Preset> template" -TestCases @(
            @{
                Preset       = "AspNetWebApiClean"
                TemplateFile = "AspNetWebApiClean.template.json"
            }
            @{
                Preset       = "WinFormsThreeLayers"
                TemplateFile = "WinFormsThreeLayers.template.json"
            }
        ) {
            New-LayeredDotnetTemplate -Preset $Preset

            $written = Get-Content `
                -Path (Join-Path $TestDrive $script:DefaultTemplateOutputPath) `
                -Raw
            $raw = Get-Content `
                -Path (Join-Path $script:templateDir $TemplateFile) `
                -Raw
            $expected = $raw -replace "{{solutionName}}", "Example"

            $written | Should -Be $expected
        }
    }

    Context "When Force is present and output file already exists" {
        BeforeAll {
            $script:outputFile = Join-Path $TestDrive "Out.json"
            [void](New-Item -Path $script:outputFile -ItemType File)

            New-LayeredDotnetTemplate `
                -OutputPath $script:outputFile `
                -Force
        }

        # 06
        It "Creates (overwrites) the file at the supplied output path" {
            $script:outputFile | Should -Exist
        }
    }
}
